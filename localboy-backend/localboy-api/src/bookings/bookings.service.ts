import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Trip } from '../entities/trip.entity';
import { TripStop } from '../entities/trip-stop.entity';
import { PoisService } from '../pois/pois.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@Injectable()
export class BookingsService {
  constructor(
    @InjectRepository(Trip)
    private tripsRepository: Repository<Trip>,
    @InjectRepository(TripStop)
    private tripStopsRepository: Repository<TripStop>,
    private poisService: PoisService,
  ) { }

  async create(userId: string, dto: CreateBookingDto): Promise<Trip> {
    // Generate unique booking code
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

    // Calculate pricing
    const selectedPois = await this.poisService.selectPoisForTrip(
      dto.hotel_lat,
      dto.hotel_lng,
      'Goa',
      dto.package_type,
    );

    const baseFare = dto.package_type === 'half_day' ? 500 : 800;
    const perStop = 100 * selectedPois.length;
    // Estimate total distance (simplified: straight-line between consecutive stops)
    let totalDistanceKm = 0;
    let prevLat = dto.hotel_lat;
    let prevLng = dto.hotel_lng;
    for (const poi of selectedPois) {
      totalDistanceKm += this.haversineDistance(prevLat, prevLng, Number(poi.lat), Number(poi.lng));
      prevLat = Number(poi.lat);
      prevLng = Number(poi.lng);
    }
    const perKm = 12 * totalDistanceKm;
    const subtotal = baseFare + perKm + perStop;
    const platformFee = Math.round(subtotal * 0.15);
    const touristCharge = Math.round(subtotal + platformFee);
    const driverPayout = Math.round(baseFare + perKm * 0.7);
    const guidePayout = dto.package_type === 'full_day' ? 500 : 0;

    const trip = this.tripsRepository.create({
      tourist_id: userId,
      trip_type: dto.package_type as 'half_day' | 'full_day',
      trip_date: dto.trip_date,
      start_time: dto.start_time,
      pickup_address: dto.hotel_address,
      pickup_lat: dto.hotel_lat,
      pickup_lng: dto.hotel_lng,
      status: 'confirmed',
      booking_code: bookingCode,
      total_distance_km: Math.round(totalDistanceKm * 100) / 100,
      tourist_charge: touristCharge,
      platform_fee: platformFee,
      driver_payout: driverPayout,
      guide_payout: guidePayout,
    });

    const savedTrip = await this.tripsRepository.save(trip);

    // Create trip stops
    let currentTime = dto.start_time;
    currentTime = this.addMinutes(currentTime, 30); // pickup buffer

    const stops: Partial<TripStop>[] = [];
    for (let i = 0; i < selectedPois.length; i++) {
      const poi = selectedPois[i];
      stops.push({
        trip_id: savedTrip.id,
        poi_id: poi.id,
        stop_order: i + 1,
        estimated_arrival: currentTime,
        status: 'pending',
      });
      currentTime = this.addMinutes(currentTime, poi.avg_visit_minutes + 20);
    }

    await this.tripStopsRepository.save(stops);

    return savedTrip;
  }

  async findByUser(userId: string): Promise<Trip[]> {
    return this.tripsRepository.find({
      where: { tourist_id: userId },
      order: { created_at: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Trip & { stops: TripStop[] }> {
    const trip = await this.tripsRepository.findOne({
      where: { id },
    });

    if (!trip) {
      throw new NotFoundException('Trip not found');
    }

    const stops = await this.tripStopsRepository
      .createQueryBuilder('stop')
      .leftJoinAndSelect('stop.poi', 'poi')
      .where('stop.trip_id = :tripId', { tripId: id })
      .orderBy('stop.stop_order', 'ASC')
      .getMany();

    return {
      ...trip,
      stops,
    };
  }

  private addMinutes(timeStr: string, minutes: number): string {
    const [hours, mins] = timeStr.split(':').map(Number);
    const totalMinutes = hours * 60 + mins + minutes;
    const newHours = Math.floor(totalMinutes / 60) % 24;
    const newMins = totalMinutes % 60;
    return `${String(newHours).padStart(2, '0')}:${String(newMins).padStart(2, '0')}`;
  }

  private haversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}
