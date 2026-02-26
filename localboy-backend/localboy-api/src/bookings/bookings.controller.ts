import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Request as ExpressRequest } from 'express';
import { BookingsService } from './bookings.service';

@Controller('bookings')
export class BookingsController {
  constructor(private bookingsService: BookingsService) {}

  @Post()
  @UseGuards(AuthGuard('jwt'))
  async create(
    @Request() req: ExpressRequest & { user?: { id: string } },
    @Body() createBookingDto: any,
  ): Promise<any> {
    const userId = req.user?.id;
    if (!userId) {
      throw new Error('User ID is required');
    }
    return this.bookingsService.create(userId, createBookingDto);
  }

  @Get('my-bookings')
  @UseGuards(AuthGuard('jwt'))
  async findByUser(
    @Request() req: ExpressRequest & { user?: { id: string } },
  ): Promise<any> {
    const userId = req.user?.id;
    if (!userId) {
      throw new Error('User ID is required');
    }
    return this.bookingsService.findByUser(userId);
  }

  @Get(':id')
  @UseGuards(AuthGuard('jwt'))
  async findOne(@Param('id') id: string) {
    return this.bookingsService.findOne(id);
  }
}
