import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('guide_profiles')
export class GuideProfile {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    user_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'user_id' })
    user: User;

    @Column('text', { array: true, nullable: true })
    languages: string[];

    @Column('text', { array: true, nullable: true })
    specializations: string[];

    @Column({ default: 0 })
    experience_years: number;

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
