import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Booking } from './booking.entity';
import { Poi } from './poi.entity';

@Entity('itineraries')
export class Itinerary {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  booking_id: string;

  @ManyToOne(() => Booking)
  @JoinColumn({ name: 'booking_id' })
  booking: Booking;

  @Column()
  poi_id: string;

  @ManyToOne(() => Poi)
  @JoinColumn({ name: 'poi_id' })
  poi: Poi;

  @Column()
  stop_order: number;

  @Column('time', { nullable: true })
  estimated_arrival: string;

  @Column({ default: 'pending' })
  status: string;
}
