import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './jwt.strategy';
import { EmailService } from './email.service';
import { User } from '../entities/user.entity';
import { OtpVerification } from '../entities/otp-verification.entity';
import { SmsService } from '../sms/sms.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, OtpVerification]),
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: { expiresIn: '30d' },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, EmailService, SmsService],
  exports: [AuthService],
})
export class AuthModule { }
