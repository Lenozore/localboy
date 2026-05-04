import {
    Controller,
    Post,
    Get,
    Param,
    Body,
    UseGuards,
    Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Request as ExpressRequest } from 'express';
import { MessagesService } from './messages.service';
import { User } from '../entities/user.entity';
import { UnauthorizedException } from '@nestjs/common';

@Controller('messages')
export class MessagesController {
    constructor(private messagesService: MessagesService) { }

    @Post('send')
    @UseGuards(AuthGuard('jwt'))
    async send(
        @Request() req: ExpressRequest & { user?: User },
        @Body()
        body: {
            trip_id: string;
            receiver_id: string;
            content: string;
        },
    ) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        return this.messagesService.send(body.trip_id, userId, body.receiver_id, body.content);
    }

    @Get('trip/:tripId')
    @UseGuards(AuthGuard('jwt'))
    async getByTrip(@Param('tripId') tripId: string) {
        return this.messagesService.getByTrip(tripId);
    }

    @Post(':id/read')
    @UseGuards(AuthGuard('jwt'))
    async markAsRead(
        @Request() req: ExpressRequest & { user?: User },
        @Param('id') id: string,
    ) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        await this.messagesService.markAsRead(id, userId);
        return { success: true };
    }

    @Get('unread-count')
    @UseGuards(AuthGuard('jwt'))
    async getUnreadCount(@Request() req: ExpressRequest & { user?: User }) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        const count = await this.messagesService.getUnreadCount(userId);
        return { count };
    }
}
