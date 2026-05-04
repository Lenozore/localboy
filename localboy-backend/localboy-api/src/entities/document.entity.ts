import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

export type DocumentType = 'aadhar' | 'license' | 'registration' | 'insurance' | 'guide_cert';
export type DocumentStatus = 'pending' | 'approved' | 'rejected';

@Entity('documents')
export class Document {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    user_id: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'user_id' })
    user: User;

    @Column()
    doc_type: DocumentType;

    @Column('text')
    file_url: string;

    @Column({ nullable: true })
    file_name: string;

    @Column({ default: 'pending' })
    status: DocumentStatus;

    @Column({ nullable: true })
    reviewed_by: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'reviewed_by' })
    reviewer: User;

    @Column({ nullable: true })
    review_notes: string;

    @CreateDateColumn()
    uploaded_at: Date;

    @Column({ type: 'timestamp', nullable: true })
    reviewed_at: Date;
}
