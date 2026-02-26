import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { Poi } from './entities/poi.entity';
import { Booking } from './entities/booking.entity';
import { Itinerary } from './entities/itinerary.entity';
import { AuthModule } from './auth/auth.module';
import { PoisModule } from './pois/pois.module';
import { BookingsModule } from './bookings/bookings.module';

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
      entities: [User, Poi, Booking, Itinerary],
      synchronize: false,
      logging: true,
    }),
    AuthModule,
    PoisModule,
    BookingsModule,
  ],
})
export class AppModule {}
