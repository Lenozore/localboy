import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
} from 'typeorm';
import { Trip } from './trip.entity';
import { Poi } from './poi.entity';

export type StopStatus = 'pending' | 'visiting' | 'completed' | 'skipped';

@Entity('trip_stops')
export class TripStop {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    trip_id: string;

    @ManyToOne(() => Trip, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'trip_id' })
    trip: Trip;

    @Column()
    poi_id: string;

    @ManyToOne(() => Poi)
    @JoinColumn({ name: 'poi_id' })
    poi: Poi;

    @Column()
    stop_order: number;

    @Column('time', { nullable: true })
    estimated_arrival: string;

    @Column('time', { nullable: true })
    actual_arrival: string;

    @Column({ default: 'pending' })
    status: StopStatus;
}
