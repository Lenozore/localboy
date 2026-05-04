import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
} from 'typeorm';

export type OtpTargetType = 'phone' | 'email';

@Entity('otp_verifications')
export class OtpVerification {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    target: string;

    @Column()
    target_type: OtpTargetType;

    @Column({ length: 6 })
    otp_code: string;

    @Column({ type: 'timestamp' })
    expires_at: Date;

    @Column({ default: false })
    is_verified: boolean;

    @Column({ default: 0 })
    attempts: number;

    @CreateDateColumn()
    created_at: Date;
}
