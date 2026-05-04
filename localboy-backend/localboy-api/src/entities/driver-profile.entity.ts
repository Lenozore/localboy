import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('driver_profiles')
export class DriverProfile {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    user_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'user_id' })
    user: User;

    @Column({ nullable: true })
    vehicle_type: string;

    @Column({ nullable: true })
    vehicle_number: string;

    @Column({ nullable: true })
    vehicle_model: string;

    @Column({ default: false })
    is_available: boolean;

    @Column({ default: false })
    is_verified: boolean;

    @Column('decimal', { precision: 2, scale: 1, default: 0 })
    rating: number;

    @Column({ default: 0 })
    total_trips: number;

    @CreateDateColumn()
    created_at: Date;
}
