import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private twilioClient: any;
  private readonly messagingServiceSid: string;

  constructor(private configService: ConfigService) {
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN');
    this.messagingServiceSid = this.configService.get<string>('TWILIO_MESSAGING_SERVICE_SID')!;

    if (accountSid && authToken && this.messagingServiceSid) {
      try {
        const twilio = require('twilio');
        this.twilioClient = twilio(accountSid, authToken);
        this.logger.log('✅ Twilio SMS provider initialized');
      } catch (error) {
        this.logger.error(`❌ Failed to initialize Twilio client: ${error.message}`);
      }
    } else {
      this.logger.warn(
        '⚠️ Twilio credentials not fully configured. SMS OTP will be bypassed in development.',
      );
    }
  }

  /**
   * Send OTP via Twilio SMS
   */
  async sendOtp(phone: string, otp: string): Promise<boolean> {
    if (!this.twilioClient) {
      this.logger.warn(
        `[DEV] SMS Bypass: Twilio not configured. OTP for ${phone} is ${otp}`,
      );
      return true;
    }

    try {
      const message = await this.twilioClient.messages.create({
        body: `Your Localboy verification code is: ${otp}. Valid for 5 minutes.`,
        messagingServiceSid: this.messagingServiceSid,
        to: phone,
      });

      this.logger.log(`📱 OTP sent to ${phone} — SID: ${message.sid}`);
      return true;
    } catch (error: any) {
      this.logger.error(`❌ Twilio send error: ${error.message}`);
      return false;
    }
  }
}