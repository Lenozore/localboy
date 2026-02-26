import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('send-otp')
  async sendOtp(@Body() body: { phone: string }): Promise<any> {
    return this.authService.sendOtp(body.phone);
  }

  @Post('verify-otp')
  async verifyOtp(@Body() body: { phone: string; otp: string }) {
    return this.authService.verifyOtp(body.phone, body.otp);
  }
}
