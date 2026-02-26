/* eslint-disable @typescript-eslint/no-unsafe-assignment,@typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-argument */
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Booking } from '../entities/booking.entity';
import { Itinerary } from '../entities/itinerary.entity';
import { PoisService } from '../pois/pois.service';

@Injectable()
export class BookingsService {
  constructor(
    @InjectRepository(Booking)
    private bookingsRepository: Repository<Booking>,
    @InjectRepository(Itinerary)
    private itinerariesRepository: Repository<Itinerary>,
    private poisService: PoisService,
  ) {}

  async create(userId: string, createBookingDto: any) {
    const bookingCode = `LB-${Math.floor(1000 + Math.random() * 9000)}`;
    const totalAmount =
      createBookingDto.package_type === 'half_day' ? 1499 : 2499;

    const booking = this.bookingsRepository.create({
      user_id: userId,
      booking_code: bookingCode,
      trip_date: createBookingDto.trip_date,
      start_time: createBookingDto.start_time,
      package_type: createBookingDto.package_type,
      hotel_address: createBookingDto.hotel_address,
      hotel_lat: createBookingDto.hotel_lat,
      hotel_lng: createBookingDto.hotel_lng,
      status: 'confirmed',
      total_amount: totalAmount,
    });

    const savedBooking = await this.bookingsRepository.save(booking);

    const selectedPois = await this.poisService.selectPoisForBooking(
      createBookingDto.hotel_lat,
      createBookingDto.hotel_lng,
      'Goa',
      createBookingDto.package_type,
    );

    let currentTime = this.parseTime(createBookingDto.start_time);
    currentTime = this.addMinutes(currentTime, 30);

    for (let i = 0; i < selectedPois.length; i++) {
      const poi = selectedPois[i];
      
      const itinerary = this.itinerariesRepository.create({
        booking_id: savedBooking.id,
        poi_id: poi.id,
        stop_order: i + 1,
        estimated_arrival: currentTime,
        status: 'pending',
      });

      await this.itinerariesRepository.save(itinerary);
      currentTime = this.addMinutes(currentTime, poi.avg_visit_minutes + 20);
    }

    return savedBooking;
  }

  async findByUser(userId: string) {
    return this.bookingsRepository.find({
      where: { user_id: userId },
      order: { created_at: 'DESC' },
    });
  }

  async findOne(id: string) {
    const booking = await this.bookingsRepository.findOne({
      where: { id },
    });

    const itinerary = await this.itinerariesRepository
      .createQueryBuilder('itinerary')
      .leftJoinAndSelect('itinerary.poi', 'poi')
      .where('itinerary.booking_id = :bookingId', { bookingId: id })
      .orderBy('itinerary.stop_order', 'ASC')
      .getMany();

    return {
      ...booking,
      itinerary,
    };
  }

  private parseTime(timeStr: string): string {
    return timeStr;
  }

  private addMinutes(timeStr: string, minutes: number): string {
    const [hours, mins] = timeStr.split(':').map(Number);
    const totalMinutes = hours * 60 + mins + minutes;
    const newHours = Math.floor(totalMinutes / 60) % 24;
    const newMins = totalMinutes % 60;
    return `${String(newHours).padStart(2, '0')}:${String(newMins).padStart(2, '0')}`;
  }
}
