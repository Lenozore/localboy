import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
    UpdateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

export type TripType = 'half_day' | 'full_day';
export type TripStatus = 'pending' | 'confirmed' | 'driver_assigned' | 'active' | 'completed' | 'cancelled';

@Entity('trips')
export class Trip {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    tourist_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'tourist_id' })
    tourist: User;

    @Column({ nullable: true })
    driver_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'driver_id' })
    driver: User;

    @Column({ nullable: true })
    guide_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'guide_id' })
    guide: User;

    @Column()
    trip_type: TripType;

    @Column('date')
    trip_date: Date;

    @Column('time')
    start_time: string;

    @Column('time', { nullable: true })
    end_time: string;

    @Column('text')
    pickup_address: string;

    @Column('decimal', { precision: 10, scale: 8 })
    pickup_lat: number;

    @Column('decimal', { precision: 11, scale: 8 })
    pickup_lng: number;

    @Column({ default: 'pending' })
    status: TripStatus;

    @Column('decimal', { precision: 8, scale: 2, default: 0 })
    total_distance_km: number;

    @Column('decimal', { precision: 10, scale: 2 })
    tourist_charge: number;

    @Column('decimal', { precision: 10, scale: 2, default: 0 })
    platform_fee: number;

    @Column('decimal', { precision: 10, scale: 2, default: 0 })
    driver_payout: number;

    @Column('decimal', { precision: 10, scale: 2, default: 0 })
    guide_payout: number;

    @Column({ unique: true, nullable: true })
    booking_code: string;

    @Column('text', { nullable: true })
    cancellation_reason: string;

    @Column({ nullable: true })
    tourist_rating: number;

    @Column({ nullable: true })
    driver_rating: number;

    @Column({ nullable: true })
    guide_rating: number;

    @CreateDateColumn()
    created_at: Date;

    @UpdateDateColumn()
    updated_at: Date;
}
