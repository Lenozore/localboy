import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User } from '../entities/user.entity';
import { Trip } from '../entities/trip.entity';
import { Payment } from '../entities/payment.entity';
import { Document } from '../entities/document.entity';
import { Complaint } from '../entities/complaint.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([User, Trip, Payment, Document, Complaint]),
    ],
    controllers: [AdminController],
    providers: [AdminService],
})
export class AdminModule { }
