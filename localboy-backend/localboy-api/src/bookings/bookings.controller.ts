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
import { CreateBookingDto } from './dto/create-booking.dto';
import { UnauthorizedException } from '@nestjs/common';
import { User } from '../entities/user.entity';

@Controller('bookings')
export class BookingsController {
  constructor(private bookingsService: BookingsService) { }

  @Post()
  @UseGuards(AuthGuard('jwt'))
  async create(
    @Request() req: ExpressRequest & { user?: User },
    @Body() createBookingDto: CreateBookingDto,
  ) {
    const userId = req.user?.id;
    if (!userId) {
      throw new UnauthorizedException('User ID is required');
    }
    return this.bookingsService.create(userId, createBookingDto);
  }

  @Get('my-bookings')
  @UseGuards(AuthGuard('jwt'))
  async findByUser(
    @Request() req: ExpressRequest & { user?: User },
  ) {
    const userId = req.user?.id;
    if (!userId) {
      throw new UnauthorizedException('User ID is required');
    }
    return this.bookingsService.findByUser(userId);
  }

  @Get(':id')
  @UseGuards(AuthGuard('jwt'))
  async findOne(@Param('id') id: string) {
    return this.bookingsService.findOne(id);
  }
}
