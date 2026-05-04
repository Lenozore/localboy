import {
    Controller,
    Post,
    Get,
    Body,
    Param,
    UseGuards,
    Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Request as ExpressRequest } from 'express';
import { TripPlannerService } from './trip-planner.service';
import { PricingService, PriceBreakdown } from './pricing.service';
import { User } from '../entities/user.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Trip } from '../entities/trip.entity';
import { TripStop } from '../entities/trip-stop.entity';
import { UnauthorizedException, NotFoundException } from '@nestjs/common';

@Controller('trips')
export class TripsController {
    constructor(
        private tripPlannerService: TripPlannerService,
        private pricingService: PricingService,
        @InjectRepository(Trip)
        private tripsRepository: Repository<Trip>,
        @InjectRepository(TripStop)
        private tripStopsRepository: Repository<TripStop>,
    ) { }

    /**
     * Plan a trip (AI-powered, no payment yet)
     * POST /api/trips/plan
     */
    @Post('plan')
    @UseGuards(AuthGuard('jwt'))
    async planTrip(
        @Body()
        body: {
            start_lat: number;
            start_lng: number;
            trip_type: 'half_day' | 'full_day';
            start_time: string;
            preferences?: string[];
        },
    ) {
        const plan = await this.tripPlannerService.planTrip(
            body.start_lat,
            body.start_lng,
            body.trip_type,
            body.start_time,
            body.preferences,
        );

        const pricing = this.pricingService.calculate(
            body.trip_type,
            plan.totalDistanceKm,
            plan.stops.length,
        );

        return { plan, pricing };
    }

    /**
     * Recalculate price after adding/removing stops
     * POST /api/trips/recalculate
     */
    @Post('recalculate')
    @UseGuards(AuthGuard('jwt'))
    async recalculate(
        @Body()
        body: {
            trip_type: 'half_day' | 'full_day';
            distance_km: number;
            stop_count: number;
        },
    ): Promise<PriceBreakdown> {
        return this.pricingService.recalculate(
            body.trip_type,
            body.distance_km,
            body.stop_count,
        );
    }

    /**
     * Create and confirm a trip (after payment)
     * POST /api/trips/create
     */
    @Post('create')
    @UseGuards(AuthGuard('jwt'))
    async createTrip(
        @Request() req: ExpressRequest & { user?: User },
        @Body()
        body: {
            trip_type: 'half_day' | 'full_day';
            trip_date: string;
            start_time: string;
            pickup_address: string;
            pickup_lat: number;
            pickup_lng: number;
            poi_ids: string[];
            total_distance_km: number;
            tourist_charge: number;
            platform_fee: number;
            driver_payout: number;
            guide_payout: number;
        },
    ) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        // Generate booking code
        let bookingCode: string;
        let attempts = 0;
        do {
            bookingCode = `LB-${Math.floor(1000 + Math.random() * 9000)}`;
            const existing = await this.tripsRepository.findOne({
                where: { booking_code: bookingCode },
            });
            if (!existing) break;
            attempts++;
        } while (attempts < 10);

        const trip = this.tripsRepository.create({
            tourist_id: userId,
            trip_type: body.trip_type,
            trip_date: body.trip_date,
            start_time: body.start_time,
            pickup_address: body.pickup_address,
            pickup_lat: body.pickup_lat,
            pickup_lng: body.pickup_lng,
            status: 'confirmed',
            booking_code: bookingCode,
            total_distance_km: body.total_distance_km,
            tourist_charge: body.tourist_charge,
            platform_fee: body.platform_fee,
            driver_payout: body.driver_payout,
            guide_payout: body.guide_payout,
        });

        const savedTrip = await this.tripsRepository.save(trip);

        // Create stops
        let currentTime = body.start_time;
        currentTime = this.addMinutes(currentTime, 30);

        const stops: Partial<TripStop>[] = body.poi_ids.map((poiId, i) => {
            const stop: Partial<TripStop> = {
                trip_id: savedTrip.id,
                poi_id: poiId,
                stop_order: i + 1,
                estimated_arrival: currentTime,
                status: 'pending',
            };
            currentTime = this.addMinutes(currentTime, 60); // avg visit
            return stop;
        });

        await this.tripStopsRepository.save(stops);

        return { trip: savedTrip, booking_code: bookingCode };
    }

    /**
     * Get user's trips
     * GET /api/trips/my-trips
     */
    @Get('my-trips')
    @UseGuards(AuthGuard('jwt'))
    async getMyTrips(@Request() req: ExpressRequest & { user?: User }) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        return this.tripsRepository.find({
            where: { tourist_id: userId },
            order: { created_at: 'DESC' },
        });
    }

    /**
     * Get trip details with stops
     * GET /api/trips/:id
     */
    @Get(':id')
    @UseGuards(AuthGuard('jwt'))
    async getTripDetails(@Param('id') id: string) {
        const trip = await this.tripsRepository.findOne({ where: { id } });
        if (!trip) throw new NotFoundException('Trip not found');

        const stops = await this.tripStopsRepository
            .createQueryBuilder('stop')
            .leftJoinAndSelect('stop.poi', 'poi')
            .where('stop.trip_id = :tripId', { tripId: id })
            .orderBy('stop.stop_order', 'ASC')
            .getMany();

        return { ...trip, stops };
    }

    /**
     * Add a stop to existing trip and recalculate
     * POST /api/trips/:id/add-stop
     */
    @Post(':id/add-stop')
    @UseGuards(AuthGuard('jwt'))
    async addStop(
        @Param('id') id: string,
        @Body() body: { poi_id: string },
    ) {
        const trip = await this.tripsRepository.findOne({ where: { id } });
        if (!trip) throw new NotFoundException('Trip not found');

        const maxOrder = await this.tripStopsRepository
            .createQueryBuilder('stop')
            .where('stop.trip_id = :tripId', { tripId: id })
            .select('MAX(stop.stop_order)', 'max')
            .getRawOne();

        const newStop = this.tripStopsRepository.create({
            trip_id: id,
            poi_id: body.poi_id,
            stop_order: (maxOrder?.max || 0) + 1,
            status: 'pending',
        });

        await this.tripStopsRepository.save(newStop);

        // Get updated stop count
        const stopCount = await this.tripStopsRepository.count({ where: { trip_id: id } });

        // Recalculate price
        const pricing = this.pricingService.recalculate(
            trip.trip_type,
            Number(trip.total_distance_km),
            stopCount,
        );

        // Update trip amounts
        trip.tourist_charge = pricing.totalTouristCharge;
        trip.platform_fee = pricing.platformFee;
        trip.driver_payout = pricing.driverPayout;
        trip.guide_payout = pricing.guidePayout;
        await this.tripsRepository.save(trip);

        return { stop: newStop, pricing, trip };
    }

    /**
     * Remove a stop from trip and recalculate
     * Post /api/trips/:id/remove-stop/:stopId
     */
    @Post(':id/remove-stop/:stopId')
    @UseGuards(AuthGuard('jwt'))
    async removeStop(
        @Param('id') id: string,
        @Param('stopId') stopId: string,
    ) {
        const trip = await this.tripsRepository.findOne({ where: { id } });
        if (!trip) throw new NotFoundException('Trip not found');

        await this.tripStopsRepository.delete({ id: stopId, trip_id: id });

        const stopCount = await this.tripStopsRepository.count({ where: { trip_id: id } });

        const pricing = this.pricingService.recalculate(
            trip.trip_type,
            Number(trip.total_distance_km),
            stopCount,
        );

        trip.tourist_charge = pricing.totalTouristCharge;
        trip.platform_fee = pricing.platformFee;
        trip.driver_payout = pricing.driverPayout;
        trip.guide_payout = pricing.guidePayout;
        await this.tripsRepository.save(trip);

        return { pricing, trip };
    }

    private addMinutes(timeStr: string, minutes: number): string {
        const [hours, mins] = timeStr.split(':').map(Number);
        const total = hours * 60 + mins + minutes;
        return `${String(Math.floor(total / 60) % 24).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
    }
}
