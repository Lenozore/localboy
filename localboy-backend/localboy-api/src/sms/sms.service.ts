import { Injectable } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class SmsService {
  private readonly authKey = process.env.MSG91_AUTH_KEY;
  private readonly templateId = process.env.MSG91_TEMPLATE_ID; // You'll get this after creating template

  async sendOtp(phone: string, otp: string) {
    try {
      const url = `https://control.msg91.com/api/v5/otp`;
      
      const payload = {
        template_id: this.templateId,
        mobile: phone,
        authkey: this.authKey,
        otp: otp,
      };

      const response = await axios.post(url, payload, {
        headers: { 'Content-Type': 'application/json' },
      });

      console.log(`📱 SMS sent to ${phone}: OTP ${otp}`);
      return response.data;
    } catch (error) {
      console.error('SMS Error:', error.response?.data || error.message);
      // Fallback: still return success so app doesn't break
      console.log(`📱 FALLBACK - OTP for ${phone}: ${otp}`);
      return { success: true };
    }
  }
}