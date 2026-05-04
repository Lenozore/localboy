import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export type UserRole = 'tourist' | 'driver' | 'guide' | 'admin';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: true })
  phone: string;

  @Column({ unique: true, nullable: true })
  email: string;

  @Column({ nullable: true })
  name: string;

  @Column({ type: 'date', nullable: true })
  dob: Date;

  @Column({ nullable: true })
  avatar_url: string;

  @Column({ unique: true, nullable: true })
  google_id: string;

  @Column({ default: 'tourist' })
  role: UserRole;

  @Column({ default: false })
  is_phone_verified: boolean;

  @Column({ default: false })
  is_email_verified: boolean;

  @Column({ default: false })
  is_profile_complete: boolean;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
