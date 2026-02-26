import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { User } from '../entities/user.entity';

@Injectable()
export class AuthService {
  private otpStore = new Map<string, string>();

  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
  ) {}

  // eslint-disable-next-line @typescript-eslint/require-await
  async sendOtp(phone: string): Promise<any> {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    this.otpStore.set(phone, otp);
    setTimeout(() => this.otpStore.delete(phone), 5 * 60 * 1000);

    console.log(`📱 OTP for ${phone}: ${otp}`);
    
    return {
      success: true,
      message: 'OTP sent successfully',
      otp: otp,
    };
  }

  async verifyOtp(phone: string, otp: string) {
    const storedOtp = this.otpStore.get(phone);

    if (!storedOtp || storedOtp !== otp) {
      throw new UnauthorizedException('Invalid OTP');
    }

    this.otpStore.delete(phone);

    let user = await this.userRepository.findOne({ where: { phone } });

    if (!user) {
      user = this.userRepository.create({ phone });
      await this.userRepository.save(user);
    }

    const token = this.jwtService.sign({
      sub: user.id,
      phone: user.phone,
    });

    return {
      token,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    };
  }

  async validateUser(userId: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { id: userId } });
  }
}
