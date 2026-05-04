import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
    private readonly logger = new Logger(EmailService.name);
    private transporter: nodemailer.Transporter;

    constructor() {
        // Gmail SMTP — requires App Password (not regular password)
        // To set up: Google Account → Security → 2FA → App Passwords → create one for "Mail"
        this.transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.EMAIL_USER,     // your Gmail address
                pass: process.env.EMAIL_APP_PASS, // Gmail App Password (16 chars)
            },
        });
    }

    async sendOtp(email: string, otp: string): Promise<boolean> {
        if (!process.env.EMAIL_USER || !process.env.EMAIL_APP_PASS) {
            this.logger.warn(`Email not configured. OTP for ${email}: ${otp}`);
            return true; // Fallback for development
        }

        try {
            await this.transporter.sendMail({
                from: `"Local Boy" <${process.env.EMAIL_USER}>`,
                to: email,
                subject: 'Your Local Boy Verification Code',
                html: `
          <div style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
            <div style="text-align: center; margin-bottom: 24px;">
              <h1 style="color: #2196F3; margin: 0;">Local Boy</h1>
              <p style="color: #666; margin-top: 4px;">Explore Like a Local</p>
            </div>
            <div style="background: #f5f5f5; border-radius: 12px; padding: 24px; text-align: center;">
              <p style="color: #333; font-size: 16px; margin-bottom: 8px;">Your verification code is:</p>
              <div style="background: #2196F3; color: white; font-size: 32px; font-weight: bold; letter-spacing: 8px; padding: 16px 24px; border-radius: 8px; display: inline-block;">
                ${otp}
              </div>
              <p style="color: #999; font-size: 13px; margin-top: 16px;">This code expires in 5 minutes.</p>
            </div>
            <p style="color: #999; font-size: 12px; text-align: center; margin-top: 24px;">
              If you didn't request this code, please ignore this email.
            </p>
          </div>
        `,
            });

            this.logger.log(`Email OTP sent to ${email}`);
            return true;
        } catch (error) {
            const err = error as { message?: string };
            this.logger.error(`Email send failed for ${email}:`, err.message);
            this.logger.warn(`FALLBACK — Email OTP for ${email}: ${otp}`);
            return true;
        }
    }
}
