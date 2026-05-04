import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Trip } from '../entities/trip.entity';
import { TripStop } from '../entities/trip-stop.entity';
import { Payment } from '../entities/payment.entity';
import { DriverProfile } from '../entities/driver-profile.entity';
import { GuideProfile } from '../entities/guide-profile.entity';
import { PaymentsService } from '../payments/payments.service';

@Injectable()
export class TripLifecycleService {
    private readonly logger = new Logger(TripLifecycleService.name);

    constructor(
        @InjectRepository(Trip)
        private tripsRepository: Repository<Trip>,
        @InjectRepository(TripStop)
        private tripStopsRepository: Repository<TripStop>,
        @InjectRepository(DriverProfile)
        private driverProfilesRepository: Repository<DriverProfile>,
        @InjectRepository(GuideProfile)
        private guideProfilesRepository: Repository<GuideProfile>,
        private paymentsService: PaymentsService,
    ) { }

    // ─── FIND AVAILABLE DRIVERS ──────────────────────────

    async findAvailableDrivers(tripId: string): Promise<DriverProfile[]> {
        const trip = await this.tripsRepository.findOne({ where: { id: tripId } });
        if (!trip) throw new NotFoundException('Trip not found');

        return this.driverProfilesRepository.find({
            where: {
                is_available: true,
                is_verified: true,
            },
            relations: ['user'],
            order: { rating: 'DESC' },
            take: 10,
        });
    }

    // ─── ASSIGN DRIVER ──────────────────────────────────

    async assignDriver(tripId: string, driverId: string): Promise<Trip> {
        const trip = await this.tripsRepository.findOne({ where: { id: tripId } });
        if (!trip) throw new NotFoundException('Trip not found');

        if (trip.status !== 'confirmed' && trip.status !== 'pending') {
            throw new BadRequestException('Trip cannot be assigned in current state');
        }

        trip.driver_id = driverId;
        trip.status = 'driver_assigned';
        await this.tripsRepository.save(trip);

        // Mark driver as unavailable
        await this.driverProfilesRepository.update(
            { user_id: driverId },
            { is_available: false },
        );

        this.logger.log(`Driver ${driverId} assigned to trip ${tripId}`);
        return trip;
    }

    // ─── DRIVER ACCEPTS TRIP ────────────────────────────

    async driverAcceptTrip(tripId: string, driverId: string): Promise<Trip> {
        const trip = await this.tripsRepository.findOne({ where: { id: tripId } });
        if (!trip) throw new NotFoundException('Trip not found');
        if (trip.driver_id !== driverId) {
            throw new BadRequestException('You are not assigned to this trip');
        }

        trip.status = 'driver_assigned';
        return this.tripsRepository.save(trip);
    }

    // ─── START TRIP ─────────────────────────────────────

    async startTrip(tripId: string, driverId: string): Promise<Trip> {
        const trip = await this.tripsRepository.findOne({ where: { id: tripId } });
        if (!trip) throw new NotFoundException('Trip not found');
        if (trip.driver_id !== driverId) {
            throw new BadRequestException('You are not assigned to this trip');
        }
        if (trip.status !== 'driver_assigned') {
            throw new BadRequestException('Trip cannot be started in current state');
        }

        trip.status = 'active';
        return this.tripsRepository.save(trip);
    }

    // ─── ARRIVE AT STOP ─────────────────────────────────

    async arriveAtStop(tripId: string, stopId: string): Promise<TripStop> {
        const stop = await this.tripStopsRepository.findOne({
            where: { id: stopId, trip_id: tripId },
        });
        if (!stop) throw new NotFoundException('Stop not found');

        stop.status = 'visiting';
        stop.actual_arrival = new Date().toTimeString().slice(0, 5);
        return this.tripStopsRepository.save(stop);
    }

    // ─── COMPLETE STOP ──────────────────────────────────

    async completeStop(tripId: string, stopId: string): Promise<TripStop> {
        const stop = await this.tripStopsRepository.findOne({
            where: { id: stopId, trip_id: tripId },
        });
        if (!stop) throw new NotFoundException('Stop not found');

        stop.status = 'completed';
        return this.tripStopsRepository.save(stop);
    }

    // ─── COMPLETE TRIP (triggers payouts) ───────────────

    async completeTrip(tripId: string, driverId: string): Promise<{
        trip: Trip;
        driverPayout: Payment;
        guidePayout: Payment | null;
    }> {
        const trip = await this.tripsRepository.findOne({ where: { id: tripId } });
        if (!trip) throw new NotFoundException('Trip not found');
        if (trip.driver_id !== driverId) {
            throw new BadRequestException('You are not assigned to this trip');
        }
        if (trip.status !== 'active') {
            throw new BadRequestException('Trip must be active to complete');
        }

        // Update trip status
        trip.status = 'completed';
        trip.end_time = new Date().toTimeString().slice(0, 5);
        await this.tripsRepository.save(trip);

        // Mark driver as available again
        await this.driverProfilesRepository.update(
            { user_id: driverId },
            { is_available: true },
        );

        // Increment driver trip count
        await this.driverProfilesRepository.increment(
            { user_id: driverId },
            'total_trips',
            1,
        );

        // ─── AUTOMATED PAYOUTS ──────────────────
        // Platform fee already deducted from tourist_charge

        // Driver payout
        const driverPayout = await this.paymentsService.initiatePayout(
            tripId,
            driverId,
            Number(trip.driver_payout),
            'driver_payout',
        );

        // Guide payout (if guide assigned)
        let guidePayout: Payment | null = null;
        if (trip.guide_id && Number(trip.guide_payout) > 0) {
            guidePayout = await this.paymentsService.initiatePayout(
                tripId,
                trip.guide_id,
                Number(trip.guide_payout),
                'guide_payout',
            );

            await this.guideProfilesRepository.increment(
                { user_id: trip.guide_id },
                'total_trips',
                1,
            );
        }

        this.logger.log(
            `Trip ${tripId} completed. Driver payout: ₹${trip.driver_payout}` +
            (guidePayout ? `, Guide payout: ₹${trip.guide_payout}` : ''),
        );

        return { trip, driverPayout, guidePayout };
    }

    // ─── CANCEL TRIP ────────────────────────────────────

    async cancelTrip(tripId: string, userId: string, reason: string): Promise<Trip> {
        const trip = await this.tripsRepository.findOne({ where: { id: tripId } });
        if (!trip) throw new NotFoundException('Trip not found');

        if (trip.status === 'completed') {
            throw new BadRequestException('Cannot cancel a completed trip');
        }

        trip.status = 'cancelled';
        trip.cancellation_reason = reason;
        await this.tripsRepository.save(trip);

        // Free up driver
        if (trip.driver_id) {
            await this.driverProfilesRepository.update(
                { user_id: trip.driver_id },
                { is_available: true },
            );
        }

        return trip;
    }

    // ─── RATE TRIP ──────────────────────────────────────

    async rateTrip(
        tripId: string,
        touristId: string,
        driverRating?: number,
        guideRating?: number,
    ): Promise<Trip> {
        const trip = await this.tripsRepository.findOne({ where: { id: tripId } });
        if (!trip) throw new NotFoundException('Trip not found');
        if (trip.tourist_id !== touristId) {
            throw new BadRequestException('Only the tourist can rate this trip');
        }

        if (driverRating) {
            trip.driver_rating = driverRating;
            // Update driver's average rating
            const driver = await this.driverProfilesRepository.findOne({
                where: { user_id: trip.driver_id },
            });
            if (driver) {
                const totalRatings = driver.total_trips;
                driver.rating = Math.round(
                    ((Number(driver.rating) * (totalRatings - 1) + driverRating) / totalRatings) * 10,
                ) / 10;
                await this.driverProfilesRepository.save(driver);
            }
        }

        if (guideRating) {
            trip.guide_rating = guideRating;
        }

        return this.tripsRepository.save(trip);
    }
}
