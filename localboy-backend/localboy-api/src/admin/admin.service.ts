import {
    Injectable,
    UnauthorizedException,
    ConflictException,
    Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not, IsNull } from 'typeorm';
import * as crypto from 'crypto';
import { User } from '../entities/user.entity';
import { Trip } from '../entities/trip.entity';
import { Payment } from '../entities/payment.entity';
import { Document } from '../entities/document.entity';
import { Complaint } from '../entities/complaint.entity';

// ─── HARDCODED DEVELOPER CREDENTIALS ──────────────────
// Only this email+password can access the developer section
const DEVELOPER_EMAIL = 'dev@localboy.app';
const DEVELOPER_PASSWORD = 'L0c4lB0y_D3v!2025';

@Injectable()
export class AdminService {
    private readonly logger = new Logger(AdminService.name);

    // Simple in-memory admin store (production: use a proper table)
    private admins: Map<
        string,
        { email: string; passwordHash: string; name: string; createdAt: Date }
    > = new Map();

    constructor(
        @InjectRepository(User)
        private usersRepository: Repository<User>,
        @InjectRepository(Trip)
        private tripsRepository: Repository<Trip>,
        @InjectRepository(Payment)
        private paymentsRepository: Repository<Payment>,
        @InjectRepository(Document)
        private documentsRepository: Repository<Document>,
        @InjectRepository(Complaint)
        private complaintsRepository: Repository<Complaint>,
    ) { }

    // ─── HELPERS ───────────────────────────────────────

    private hashPassword(password: string): string {
        return crypto.createHash('sha256').update(password).digest('hex');
    }

    private generateToken(email: string, role: string): string {
        const payload = { email, role, ts: Date.now() };
        return Buffer.from(JSON.stringify(payload)).toString('base64');
    }

    // ─── ADMIN AUTH ────────────────────────────────────

    async signup(
        email: string,
        password: string,
        name: string,
    ): Promise<{ token: string; admin: { email: string; name: string } }> {
        // Cannot use developer email for admin
        if (email.toLowerCase() === DEVELOPER_EMAIL.toLowerCase()) {
            throw new ConflictException('This email cannot be used for admin signup');
        }

        if (this.admins.has(email.toLowerCase())) {
            throw new ConflictException('Admin with this email already exists');
        }

        if (password.length < 6) {
            throw new UnauthorizedException('Password must be at least 6 characters');
        }

        const passwordHash = this.hashPassword(password);
        this.admins.set(email.toLowerCase(), {
            email,
            passwordHash,
            name,
            createdAt: new Date(),
        });

        const token = this.generateToken(email, 'admin');
        this.logger.log(`Admin signed up: ${email}`);

        return { token, admin: { email, name } };
    }

    async login(
        email: string,
        password: string,
    ): Promise<{ token: string; admin: { email: string; name: string } }> {
        const admin = this.admins.get(email.toLowerCase());
        if (!admin) {
            throw new UnauthorizedException('No admin account found. Please sign up first.');
        }

        const passwordHash = this.hashPassword(password);
        if (admin.passwordHash !== passwordHash) {
            throw new UnauthorizedException('Invalid password');
        }

        const token = this.generateToken(email, 'admin');
        return { token, admin: { email: admin.email, name: admin.name } };
    }

    // ─── DEVELOPER AUTH (hardcoded) ────────────────────

    async developerLogin(
        email: string,
        password: string,
    ): Promise<{ token: string }> {
        if (
            email.toLowerCase() !== DEVELOPER_EMAIL.toLowerCase() ||
            password !== DEVELOPER_PASSWORD
        ) {
            throw new UnauthorizedException('Invalid developer credentials');
        }

        const token = this.generateToken(email, 'developer');
        this.logger.log('Developer login successful');
        return { token };
    }

    // ─── DASHBOARD STATS ──────────────────────────────

    async getDashboardStats(): Promise<{
        totalUsers: number;
        totalTrips: number;
        totalRevenue: number;
        pendingDocs: number;
        tourists: number;
        drivers: number;
        guides: number;
        activeTrips: number;
    }> {
        const totalUsers = await this.usersRepository.count();
        const tourists = await this.usersRepository.count({ where: { role: 'tourist' } });
        const drivers = await this.usersRepository.count({ where: { role: 'driver' } });
        const guides = await this.usersRepository.count({ where: { role: 'guide' } });
        const totalTrips = await this.tripsRepository.count();
        const activeTrips = await this.tripsRepository.count({ where: { status: 'active' } });

        // Sum of all completed trip payments
        const revenueResult = await this.paymentsRepository
            .createQueryBuilder('p')
            .select('COALESCE(SUM(p.amount), 0)', 'total')
            .where('p.payment_type = :type', { type: 'trip_payment' })
            .andWhere('p.status = :status', { status: 'completed' })
            .getRawOne();

        const totalRevenue = parseFloat(revenueResult?.total || '0');

        const pendingDocs = await this.documentsRepository.count({
            where: { status: 'pending' },
        });

        return {
            totalUsers,
            totalTrips,
            totalRevenue,
            pendingDocs,
            tourists,
            drivers,
            guides,
            activeTrips,
        };
    }

    // ─── RECENT ACTIVITY ──────────────────────────────

    async getRecentActivity(): Promise<
        Array<{ text: string; time: string; type: string }>
    > {
        const activities: Array<{ text: string; time: string; type: string }> = [];

        // Recent users
        const recentUsers = await this.usersRepository.find({
            order: { created_at: 'DESC' },
            take: 3,
        });
        for (const u of recentUsers) {
            activities.push({
                text: `New ${u.role} registered: ${u.name || u.phone}`,
                time: this.timeAgo(u.created_at),
                type: 'user',
            });
        }

        // Recent trips
        const recentTrips = await this.tripsRepository.find({
            order: { created_at: 'DESC' },
            take: 3,
        });
        for (const t of recentTrips) {
            activities.push({
                text: `Trip ${t.booking_code} — status: ${t.status}${t.tourist_charge ? ` (₹${t.tourist_charge})` : ''}`,
                time: this.timeAgo(t.created_at),
                type: 'trip',
            });
        }

        // Recent payments
        const recentPayments = await this.paymentsRepository.find({
            order: { created_at: 'DESC' },
            take: 3,
        });
        for (const p of recentPayments) {
            activities.push({
                text: `Payment ₹${p.amount} — ${(p.payment_type as string).replace(/_/g, ' ')} (${p.status})`,
                time: this.timeAgo(p.created_at),
                type: 'payment',
            });
        }

        // Sort by most recent
        return activities.slice(0, 10);
    }

    private timeAgo(date: Date): string {
        const diff = Date.now() - new Date(date).getTime();
        const mins = Math.floor(diff / 60000);
        if (mins < 1) return 'just now';
        if (mins < 60) return `${mins} min ago`;
        const hrs = Math.floor(mins / 60);
        if (hrs < 24) return `${hrs} hr ago`;
        const days = Math.floor(hrs / 24);
        return `${days} day${days > 1 ? 's' : ''} ago`;
    }

    // ─── USERS ────────────────────────────────────────

    async getUsers(role?: string): Promise<User[]> {
        const where: Record<string, string> = {};
        if (role && role !== 'all') where['role'] = role;
        return this.usersRepository.find({
            where: Object.keys(where).length > 0 ? where : undefined,
            order: { created_at: 'DESC' },
        });
    }

    // ─── TRIPS ────────────────────────────────────────

    async getTrips(status?: string): Promise<Trip[]> {
        const where: Record<string, string> = {};
        if (status && status !== 'all') where['status'] = status;
        return this.tripsRepository.find({
            where: Object.keys(where).length > 0 ? where : undefined,
            order: { created_at: 'DESC' },
            relations: ['tourist', 'driver'],
        });
    }

    // ─── PAYMENTS ─────────────────────────────────────

    async getPayments(): Promise<Payment[]> {
        return this.paymentsRepository.find({
            order: { created_at: 'DESC' },
            take: 50,
        });
    }

    async getPaymentStats(): Promise<{
        collected: number;
        payouts: number;
        platformRevenue: number;
    }> {
        const collectedResult = await this.paymentsRepository
            .createQueryBuilder('p')
            .select('COALESCE(SUM(p.amount), 0)', 'total')
            .where('p.payment_type = :type', { type: 'trip_payment' })
            .andWhere('p.status = :status', { status: 'completed' })
            .getRawOne();

        const payoutsResult = await this.paymentsRepository
            .createQueryBuilder('p')
            .select('COALESCE(SUM(p.amount), 0)', 'total')
            .where('p.payment_type IN (:...types)', {
                types: ['driver_payout', 'guide_payout'],
            })
            .getRawOne();

        const collected = parseFloat(collectedResult?.total || '0');
        const payouts = parseFloat(payoutsResult?.total || '0');

        return {
            collected,
            payouts,
            platformRevenue: collected - payouts,
        };
    }

    // ─── DOCUMENTS ────────────────────────────────────

    async getDocuments(): Promise<Document[]> {
        return this.documentsRepository.find({
            relations: ['user'],
            order: { uploaded_at: 'DESC' },
        });
    }

    async reviewDocument(
        docId: string,
        status: 'approved' | 'rejected',
        notes?: string,
    ): Promise<Document> {
        const doc = await this.documentsRepository.findOne({ where: { id: docId } });
        if (!doc) throw new Error('Document not found');

        doc.status = status;
        if (notes) doc.review_notes = notes;
        doc.reviewed_at = new Date();

        return this.documentsRepository.save(doc);
    }

    // ─── COMPLAINTS ───────────────────────────────────

    async getComplaints(): Promise<Complaint[]> {
        return this.complaintsRepository.find({
            relations: ['user', 'trip'],
            order: { created_at: 'DESC' },
        });
    }

    // ─── DEVELOPER STATS ──────────────────────────────

    async getDeveloperStats(): Promise<{
        userCount: number;
        tripCount: number;
        paymentCount: number;
        documentCount: number;
        complaintCount: number;
        poiCount: number;
    }> {
        const [userCount, tripCount, paymentCount, documentCount, complaintCount] =
            await Promise.all([
                this.usersRepository.count(),
                this.tripsRepository.count(),
                this.paymentsRepository.count(),
                this.documentsRepository.count(),
                this.complaintsRepository.count(),
            ]);

        return {
            userCount,
            tripCount,
            paymentCount,
            documentCount,
            complaintCount,
            poiCount: 0,
        };
    }
}
