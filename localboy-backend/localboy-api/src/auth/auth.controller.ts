import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  Get,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Request as ExpressRequest } from 'express';
import { AuthService } from './auth.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { CompleteProfileDto } from './dto/complete-profile.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { User } from '../entities/user.entity';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) { }

  /**
   * Step 1: Send OTP to phone or email
   * POST /api/auth/send-otp
   */
  @Post('send-otp')
  async sendOtp(@Body() dto: SendOtpDto) {
    return this.authService.sendOtp(dto.target, dto.target_type as 'phone' | 'email');
  }

  /**
   * Step 2: Verify OTP (creates account for phone, returns JWT)
   * POST /api/auth/verify-otp
   */
  @Post('verify-otp')
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto.target, dto.target_type as 'phone' | 'email', dto.otp, dto.role);
  }

  /**
   * Step 3: Verify email (after phone verification, user is logged in)
   * POST /api/auth/verify-email
   */
  @Post('verify-email')
  @UseGuards(AuthGuard('jwt'))
  async verifyEmail(
    @Request() req: ExpressRequest & { user?: User },
    @Body() body: { email: string; otp: string },
  ) {
    const userId = req.user?.id;
    if (!userId) throw new Error('User not found');
    return this.authService.verifyEmailForUser(userId, body.email, body.otp);
  }

  /**
   * Step 4: Complete profile (name, DOB)
   * POST /api/auth/complete-profile
   */
  @Post('complete-profile')
  @UseGuards(AuthGuard('jwt'))
  async completeProfile(
    @Request() req: ExpressRequest & { user?: User },
    @Body() dto: CompleteProfileDto,
  ) {
    const userId = req.user?.id;
    if (!userId) throw new Error('User not found');
    return this.authService.completeProfile(userId, dto.name, dto.dob);
  }

  /**
   * Login with Firebase-verified phone
   * POST /api/auth/firebase-login
   */
  @Post('firebase-login')
  async firebaseLogin(@Body() body: { phone: string; firebase_uid: string; firebase_token?: string; role?: string }) {
    return this.authService.createOrLoginWithPhone(body.phone, body.role);
  }

  /**
   * Google Sign-In (alternative to phone flow)
   * POST /api/auth/google
   */
  @Post('google')
  async googleAuth(@Body() dto: GoogleAuthDto) {
    return this.authService.googleAuth(dto.id_token);
  }

  /**
   * Get current user profile
   * GET /api/auth/me
   */
  @Get('me')
  @UseGuards(AuthGuard('jwt'))
  async getProfile(@Request() req: ExpressRequest & { user?: User }) {
    return {
      user: {
        id: req.user?.id,
        phone: req.user?.phone,
        email: req.user?.email,
        name: req.user?.name,
        dob: req.user?.dob,
        avatar_url: req.user?.avatar_url,
        role: req.user?.role,
        is_phone_verified: req.user?.is_phone_verified,
        is_email_verified: req.user?.is_email_verified,
        is_profile_complete: req.user?.is_profile_complete,
      },
    };
  }
}
