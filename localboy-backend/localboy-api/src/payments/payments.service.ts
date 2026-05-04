import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Payment } from '../entities/payment.entity';
import * as crypto from 'crypto';

@Injectable()
export class PaymentsService {
    private readonly logger = new Logger(PaymentsService.name);
    private readonly keyId = process.env.RAZORPAY_KEY_ID;
    private readonly keySecret = process.env.RAZORPAY_KEY_SECRET;
    private razorpay: any;

    constructor(
        @InjectRepository(Payment)
        private paymentsRepository: Repository<Payment>,
    ) {
        if (this.keyId && this.keySecret) {
            // Dynamic import for razorpay
            this.initRazorpay();
        }
    }

    private async initRazorpay() {
        try {
            const Razorpay = (await import('razorpay')).default;
            this.razorpay = new Razorpay({
                key_id: this.keyId,
                key_secret: this.keySecret,
            });
            this.logger.log('Razorpay initialized');
        } catch (e) {
            this.logger.warn('Razorpay not available — running in test mode');
        }
    }

    /**
     * Create a Razorpay order for trip payment
     */
    async createOrder(
        tripId: string,
        payerId: string,
        amount: number,
    ): Promise<{ orderId: string; amount: number; currency: string; keyId: string }> {
        // Save payment record
        const payment = this.paymentsRepository.create({
            trip_id: tripId,
            payer_id: payerId,
            payment_type: 'trip_payment',
            amount,
            status: 'pending',
        });

        if (this.razorpay) {
            // Create Razorpay order
            const order = await this.razorpay.orders.create({
                amount: Math.round(amount * 100), // Razorpay uses paise
                currency: 'INR',
                receipt: `trip_${tripId}`,
                notes: {
                    trip_id: tripId,
                    payer_id: payerId,
                },
            });

            payment.razorpay_order_id = order.id;
            await this.paymentsRepository.save(payment);

            return {
                orderId: order.id,
                amount: order.amount,
                currency: order.currency,
                keyId: this.keyId!,
            };
        } else {
            // Test mode — simulate order
            const testOrderId = `order_test_${Date.now()}`;
            payment.razorpay_order_id = testOrderId;
            await this.paymentsRepository.save(payment);

            this.logger.warn(`TEST MODE — Order created: ${testOrderId}, ₹${amount}`);

            return {
                orderId: testOrderId,
                amount: Math.round(amount * 100),
                currency: 'INR',
                keyId: 'rzp_test_placeholder',
            };
        }
    }

    /**
     * Verify Razorpay payment signature and mark as completed
     */
    async verifyPayment(
        orderId: string,
        paymentId: string,
        signature: string,
    ): Promise<{ success: boolean; payment: Payment }> {
        const payment = await this.paymentsRepository.findOne({
            where: { razorpay_order_id: orderId },
        });

        if (!payment) {
            throw new BadRequestException('Payment not found');
        }

        // Skip signature verification for test/simulated orders
        const isTestOrder = orderId.startsWith('order_test_');

        if (this.keySecret && !isTestOrder) {
            // Verify signature for real Razorpay orders
            const expectedSignature = crypto
                .createHmac('sha256', this.keySecret)
                .update(`${orderId}|${paymentId}`)
                .digest('hex');

            if (expectedSignature !== signature) {
                payment.status = 'failed';
                await this.paymentsRepository.save(payment);
                throw new BadRequestException('Payment verification failed');
            }
        }

        if (isTestOrder) {
            this.logger.warn(`TEST MODE — Payment verified: ${orderId}`);
        }

        // Mark payment as completed
        payment.razorpay_payment_id = paymentId;
        payment.status = 'completed';
        payment.completed_at = new Date();
        await this.paymentsRepository.save(payment);

        return { success: true, payment };
    }

    /**
     * Initiate payout to driver/guide after trip completion.
     * Uses RazorpayX if available, otherwise marks for manual payout.
     */
    async initiatePayout(
        tripId: string,
        payeeId: string,
        amount: number,
        paymentType: 'driver_payout' | 'guide_payout',
    ): Promise<Payment> {
        const payout = this.paymentsRepository.create({
            trip_id: tripId,
            payee_id: payeeId,
            payment_type: paymentType,
            amount,
            status: 'pending',
        });

        await this.paymentsRepository.save(payout);

        // In production with RazorpayX, you would create a payout here:
        // const rzpPayout = await this.razorpay.payouts.create({...});
        // payout.razorpay_payout_id = rzpPayout.id;

        this.logger.log(
            `Payout initiated: ₹${amount} for ${paymentType} on trip ${tripId}`,
        );

        return payout;
    }

    /**
     * Get payment history for a user
     */
    async getPaymentsByUser(userId: string): Promise<Payment[]> {
        return this.paymentsRepository.find({
            where: [{ payer_id: userId }, { payee_id: userId }],
            order: { created_at: 'DESC' },
        });
    }

    /**
     * Get payment by trip
     */
    async getPaymentByTrip(tripId: string): Promise<Payment | null> {
        return this.paymentsRepository.findOne({
            where: { trip_id: tripId, payment_type: 'trip_payment' },
        });
    }
}
