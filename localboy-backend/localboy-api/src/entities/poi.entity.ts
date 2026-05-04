import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('pois')
export class Poi {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column('text', { nullable: true })
  description: string;

  @Column('text', { array: true, nullable: true })
  photo_urls: string[];

  @Column()
  category: string;

  @Column('decimal', { precision: 10, scale: 8 })
  lat: number;

  @Column('decimal', { precision: 11, scale: 8 })
  lng: number;

  @Column({ default: 60 })
  avg_visit_minutes: number;

  @Column({ default: 5 })
  popularity_score: number;

  @Column({ default: 'Goa' })
  city: string;

  @Column({ default: 'Goa' })
  state: string;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;
}
