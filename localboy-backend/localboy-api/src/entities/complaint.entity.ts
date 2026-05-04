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

export type ComplaintStatus = 'open' | 'investigating' | 'resolved' | 'closed';

@Entity('complaints')
export class Complaint {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ nullable: true })
    trip_id: string;

    @ManyToOne(() => Trip)
    @JoinColumn({ name: 'trip_id' })
    trip: Trip;

    @Column()
    user_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'user_id' })
    user: User;

    @Column()
    subject: string;

    @Column('text')
    description: string;

    @Column({ default: 'open' })
    status: ComplaintStatus;

    @Column({ nullable: true })
    resolved_by: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'resolved_by' })
    resolver: User;

    @Column({ nullable: true })
    resolution_notes: string;

    @CreateDateColumn()
    created_at: Date;

    @Column({ type: 'timestamp', nullable: true })
    resolved_at: Date;
}
