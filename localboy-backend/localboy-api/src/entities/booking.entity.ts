import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('bookings')
export class Booking {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  user_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ unique: true })
  booking_code: string;

  @Column('date')
  trip_date: Date;

  @Column('time')
  start_time: string;

  @Column()
  package_type: string;

  @Column('text')
  hotel_address: string;

  @Column('decimal', { precision: 10, scale: 8 })
  hotel_lat: number;

  @Column('decimal', { precision: 11, scale: 8 })
  hotel_lng: number;

  @Column({ default: 'pending' })
  status: string;

  @Column('decimal', { precision: 10, scale: 2, default: 1499 })
  total_amount: number;

  @CreateDateColumn()
  created_at: Date;
}
