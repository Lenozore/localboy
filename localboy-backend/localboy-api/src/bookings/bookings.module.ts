import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { Trip } from '../entities/trip.entity';
import { TripStop } from '../entities/trip-stop.entity';
import { PoisModule } from '../pois/pois.module';

@Module({
  imports: [TypeOrmModule.forFeature([Trip, TripStop]), PoisModule],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule { }
