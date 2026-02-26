import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { Booking } from '../entities/booking.entity';
import { Itinerary } from '../entities/itinerary.entity';
import { PoisModule } from '../pois/pois.module';

@Module({
  imports: [TypeOrmModule.forFeature([Booking, Itinerary]), PoisModule],
  controllers: [BookingsController],
  providers: [BookingsService],
})
export class BookingsModule {}
