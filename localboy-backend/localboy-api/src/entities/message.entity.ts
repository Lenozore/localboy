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

@Entity('messages')
export class Message {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    trip_id: string;

    @ManyToOne(() => Trip, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'trip_id' })
    trip: Trip;

    @Column()
    sender_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'sender_id' })
    sender: User;

    @Column()
    receiver_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'receiver_id' })
    receiver: User;

    @Column('text')
    content: string;

    @Column({ default: false })
    is_read: boolean;

    @CreateDateColumn()
    created_at: Date;
}
