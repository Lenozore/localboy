import {
    Controller,
    Post,
    Get,
    Body,
    UseGuards,
    Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Request as ExpressRequest } from 'express';
import { PaymentsService } from './payments.service';
import { User } from '../entities/user.entity';
import { UnauthorizedException } from '@nestjs/common';

@Controller('payments')
export class PaymentsController {
    constructor(private paymentsService: PaymentsService) { }

    /**
     * Create a Razorpay order for trip payment
     * POST /api/payments/create-order
     */
    @Post('create-order')
    @UseGuards(AuthGuard('jwt'))
    async createOrder(
        @Request() req: ExpressRequest & { user?: User },
        @Body() body: { trip_id: string; amount: number },
    ) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        return this.paymentsService.createOrder(body.trip_id, userId, body.amount);
    }

    /**
     * Verify Razorpay payment
     * POST /api/payments/verify
     */
    @Post('verify')
    @UseGuards(AuthGuard('jwt'))
    async verifyPayment(
        @Body()
        body: {
            order_id: string;
            payment_id: string;
            signature: string;
        },
    ) {
        return this.paymentsService.verifyPayment(
            body.order_id,
            body.payment_id,
            body.signature,
        );
    }

    /**
     * Get payment history
     * GET /api/payments/history
     */
    @Get('history')
    @UseGuards(AuthGuard('jwt'))
    async getHistory(@Request() req: ExpressRequest & { user?: User }) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        return this.paymentsService.getPaymentsByUser(userId);
    }
}
