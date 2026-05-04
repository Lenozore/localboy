import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TripsController } from './trips.controller';
import { TripPlannerService } from './trip-planner.service';
import { PricingService } from './pricing.service';
import { TripLifecycleService } from './trip-lifecycle.service';
import { Trip } from '../entities/trip.entity';
import { TripStop } from '../entities/trip-stop.entity';
import { Poi } from '../entities/poi.entity';
import { DriverProfile } from '../entities/driver-profile.entity';
import { GuideProfile } from '../entities/guide-profile.entity';
import { PaymentsModule } from '../payments/payments.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Trip, TripStop, Poi, DriverProfile, GuideProfile]),
        PaymentsModule,
    ],
    controllers: [TripsController],
    providers: [TripPlannerService, PricingService, TripLifecycleService],
    exports: [TripPlannerService, PricingService, TripLifecycleService],
})
export class TripsModule { }
