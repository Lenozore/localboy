import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
} from 'typeorm';
import { Trip } from './trip.entity';
import { User } from './user.entity';

export type PaymentType = 'trip_payment' | 'driver_payout' | 'guide_payout';
export type PaymentStatus = 'pending' | 'completed' | 'failed' | 'refunded';

@Entity('payments')
export class Payment {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    trip_id: string;

    @ManyToOne(() => Trip)
    @JoinColumn({ name: 'trip_id' })
    trip: Trip;

    @Column({ nullable: true })
    payer_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'payer_id' })
    payer: User;

    @Column({ nullable: true })
    payee_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'payee_id' })
    payee: User;

    @Column()
    payment_type: PaymentType;

    @Column('decimal', { precision: 10, scale: 2 })
    amount: number;

    @Column({ nullable: true })
    razorpay_order_id: string;

    @Column({ nullable: true })
    razorpay_payment_id: string;

    @Column({ nullable: true })
    razorpay_payout_id: string;

    @Column({ default: 'pending' })
    status: PaymentStatus;

    @CreateDateColumn()
    created_at: Date;

    @Column({ type: 'timestamp', nullable: true })
    completed_at: Date;
}
