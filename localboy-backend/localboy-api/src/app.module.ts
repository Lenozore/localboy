import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';

// Entities
import { User } from './entities/user.entity';
import { OtpVerification } from './entities/otp-verification.entity';
import { Poi } from './entities/poi.entity';
import { Trip } from './entities/trip.entity';
import { TripStop } from './entities/trip-stop.entity';
import { Payment } from './entities/payment.entity';
import { Message } from './entities/message.entity';
import { Complaint } from './entities/complaint.entity';
import { DriverProfile } from './entities/driver-profile.entity';
import { GuideProfile } from './entities/guide-profile.entity';
import { Document } from './entities/document.entity';

// Modules
import { AuthModule } from './auth/auth.module';
import { PoisModule } from './pois/pois.module';
import { BookingsModule } from './bookings/bookings.module';
import { TripsModule } from './trips/trips.module';
import { PaymentsModule } from './payments/payments.module';
import { DocumentsModule } from './documents/documents.module';
import { MessagesModule } from './messages/messages.module';
import { AdminModule } from './admin/admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DATABASE_HOST,
      port: parseInt(process.env.DATABASE_PORT || '5432', 10),
      username: process.env.DATABASE_USER,
      password: process.env.DATABASE_PASSWORD,
      database: process.env.DATABASE_NAME,
      entities: [
        User,
        OtpVerification,
        Poi,
        Trip,
        TripStop,
        Payment,
        Message,
        Complaint,
        DriverProfile,
        GuideProfile,
        Document,
      ],
      // ⚠️ WARNING: Disable synchronize in production! Use migrations instead.
      synchronize: process.env.NODE_ENV !== 'production', // true in dev, false in prod
      logging: process.env.NODE_ENV !== 'production',
    }),
    AuthModule,
    PoisModule,
    BookingsModule,
    TripsModule,
    PaymentsModule,
    DocumentsModule,
    MessagesModule,
    AdminModule,
  ],
})
export class AppModule { }
