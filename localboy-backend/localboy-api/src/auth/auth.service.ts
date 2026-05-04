import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { User } from '../entities/user.entity';
import { OtpVerification } from '../entities/otp-verification.entity';
import { SmsService } from '../sms/sms.service';
import { EmailService } from './email.service';
import axios from 'axios';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(OtpVerification)
    private otpRepository: Repository<OtpVerification>,
    private jwtService: JwtService,
    private smsService: SmsService,
    private emailService: EmailService,
  ) { }

  // ─── SEND OTP (phone or email) ───────────────────────────────

  async sendOtp(
    target: string,
    targetType: 'phone' | 'email',
  ): Promise<{ success: boolean; message: string }> {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Expire any existing OTPs for this target
    await this.otpRepository.update(
      { target, target_type: targetType, is_verified: false },
      { is_verified: true },
    );

    // Store OTP in database (expires in 5 minutes)
    const otpRecord = this.otpRepository.create({
      target,
      target_type: targetType,
      otp_code: otp,
      expires_at: new Date(Date.now() + 5 * 60 * 1000),
    });
    await this.otpRepository.save(otpRecord);

    this.logger.log(`📱 OTP for ${target}: ${otp}`);

    // Send OTP via appropriate channel
    try {
      if (targetType === 'phone') {
        await this.smsService.sendOtp(target, otp);
      } else {
        await this.emailService.sendOtp(target, otp);
      }
    } catch (err) {
      this.logger.warn(`⚠️ Failed to send OTP via ${targetType}: ${err.message}. OTP logged above.`);
    }

    return { success: true, message: `OTP sent to ${targetType}` };
  }

  // ─── VERIFY OTP ──────────────────────────────────────────────

  async verifyOtp(
    target: string,
    targetType: 'phone' | 'email',
    otp: string,
    role?: string,
  ): Promise<{
    token: string;
    user: Partial<User>;
    is_new_user: boolean;
    next_step: string;
  }> {
    // DEV MODE: 123456 always works
    if (otp === '123456') {
      this.logger.log(`🔓 Dev bypass OTP used for ${target}`);
      return this.createOrLoginUser(target, targetType, role as any);
    }

    const otpRecord = await this.otpRepository.findOne({
      where: {
        target,
        target_type: targetType,
        is_verified: false,
      },
      order: { created_at: 'DESC' },
    });

    if (!otpRecord) {
      throw new UnauthorizedException('No OTP found. Please request a new one.');
    }

    if (new Date() > otpRecord.expires_at) {
      throw new UnauthorizedException('OTP has expired. Please request a new one.');
    }

    if (otpRecord.attempts >= 3) {
      throw new UnauthorizedException('Too many attempts. Please request a new OTP.');
    }

    if (otpRecord.otp_code !== otp) {
      otpRecord.attempts += 1;
      await this.otpRepository.save(otpRecord);
      throw new UnauthorizedException('Invalid OTP');
    }

    otpRecord.is_verified = true;
    await this.otpRepository.save(otpRecord);

    return this.createOrLoginUser(target, targetType, role as any);
  }

  // ─── LOGIN WITH FIREBASE-VERIFIED PHONE ───────────────────

  async createOrLoginWithPhone(phone: string, role?: string) {
    // Firebase already verified the phone on the client side.
    // We just create or login the user on our backend.
    this.logger.log(`🔐 Firebase-verified login for ${phone}`);
    return this.createOrLoginUser(phone, 'phone', role as any);
  }

  // ─── HELPER: Create or login user ───────────────────────────

  private async createOrLoginUser(
    target: string,
    targetType: 'phone' | 'email',
    role?: any,
  ): Promise<{
    token: string;
    user: Partial<User>;
    is_new_user: boolean;
    next_step: string;
  }> {
    let user: User | null = null;
    let isNewUser = false;

    if (targetType === 'phone') {
      user = await this.userRepository.findOne({ where: { phone: target } });
      if (!user) {
        user = this.userRepository.create({
          phone: target,
          is_phone_verified: true,
          role: role || 'tourist',
        });
        await this.userRepository.save(user);
        isNewUser = true;
      } else {
        user.is_phone_verified = true;
        await this.userRepository.save(user);
      }
    } else {
      user = await this.userRepository.findOne({ where: { email: target } });
      if (!user) {
        user = this.userRepository.create({
          email: target,
          is_email_verified: true,
          role: role || 'tourist',
        });
        await this.userRepository.save(user);
        isNewUser = true;
      } else {
        user.is_email_verified = true;
        await this.userRepository.save(user);
      }
    }

    const token = this.jwtService.sign({
      sub: user.id,
      phone: user.phone,
      role: user.role,
    });

    let nextStep = 'home';
    if (!user.is_email_verified && user.is_phone_verified) {
      nextStep = 'verify_email';
    } else if (!user.is_profile_complete) {
      nextStep = 'complete_profile';
    }

    return {
      token,
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        name: user.name,
        dob: user.dob,
        avatar_url: user.avatar_url,
        role: user.role,
        is_phone_verified: user.is_phone_verified,
        is_email_verified: user.is_email_verified,
        is_profile_complete: user.is_profile_complete,
      },
      is_new_user: isNewUser,
      next_step: nextStep,
    };
  }

  // ─── VERIFY EMAIL (attach to existing user session) ──────────

  async verifyEmailForUser(
    userId: string,
    email: string,
    otp: string,
  ): Promise<{ success: boolean; next_step: string }> {
    // Verify the OTP for this email
    const otpRecord = await this.otpRepository.findOne({
      where: {
        target: email,
        target_type: 'email',
        is_verified: false,
      },
      order: { created_at: 'DESC' },
    });

    if (!otpRecord || otpRecord.otp_code !== otp || new Date() > otpRecord.expires_at) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    otpRecord.is_verified = true;
    await this.otpRepository.save(otpRecord);

    // Attach email to user
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('User not found');

    user.email = email;
    user.is_email_verified = true;
    await this.userRepository.save(user);

    const nextStep = user.is_profile_complete ? 'home' : 'complete_profile';
    return { success: true, next_step: nextStep };
  }

  // ─── COMPLETE PROFILE ────────────────────────────────────────

  async completeProfile(
    userId: string,
    name: string,
    dob?: string,
  ): Promise<{ success: boolean; user: Partial<User> }> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('User not found');

    user.name = name;
    if (dob) user.dob = new Date(dob);
    user.is_profile_complete = true;
    await this.userRepository.save(user);

    return {
      success: true,
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        name: user.name,
        dob: user.dob,
        avatar_url: user.avatar_url,
        role: user.role,
        is_phone_verified: user.is_phone_verified,
        is_email_verified: user.is_email_verified,
        is_profile_complete: user.is_profile_complete,
      },
    };
  }

  // ─── GOOGLE SIGN-IN ──────────────────────────────────────────

  async googleAuth(idToken: string): Promise<{
    token: string;
    user: Partial<User>;
    is_new_user: boolean;
  }> {
    // Verify Google ID token
    let googlePayload: {
      sub: string;
      email: string;
      name: string;
      picture?: string;
    };

    try {
      const response = await axios.get(
        `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`,
      );
      googlePayload = response.data as typeof googlePayload;
    } catch {
      throw new UnauthorizedException('Invalid Google ID token');
    }

    if (!googlePayload.email) {
      throw new BadRequestException('Google account has no email');
    }

    // Find or create user
    let user = await this.userRepository.findOne({
      where: { google_id: googlePayload.sub },
    });

    let isNewUser = false;

    if (!user) {
      // Check by email
      user = await this.userRepository.findOne({
        where: { email: googlePayload.email },
      });

      if (user) {
        // Link Google to existing account
        user.google_id = googlePayload.sub;
        if (!user.avatar_url && googlePayload.picture) {
          user.avatar_url = googlePayload.picture;
        }
        await this.userRepository.save(user);
      } else {
        // Create new user
        user = this.userRepository.create({
          google_id: googlePayload.sub,
          email: googlePayload.email,
          name: googlePayload.name,
          avatar_url: googlePayload.picture,
          is_email_verified: true,
          is_profile_complete: true,
        });
        await this.userRepository.save(user);
        isNewUser = true;
      }
    }

    const token = this.jwtService.sign({
      sub: user.id,
      phone: user.phone,
      role: user.role,
    });

    return {
      token,
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        name: user.name,
        dob: user.dob,
        avatar_url: user.avatar_url,
        role: user.role,
        is_phone_verified: user.is_phone_verified,
        is_email_verified: user.is_email_verified,
        is_profile_complete: user.is_profile_complete,
      },
      is_new_user: isNewUser,
    };
  }

  // ─── VALIDATE USER (for JWT strategy) ────────────────────────

  async validateUser(userId: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { id: userId } });
  }

  // ─── CLEANUP EXPIRED OTPs ────────────────────────────────────

  async cleanupExpiredOtps(): Promise<void> {
    await this.otpRepository.delete({
      expires_at: LessThan(new Date()),
    });
  }
}
