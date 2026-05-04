import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Query,
    UnauthorizedException,
} from '@nestjs/common';
import { AdminService } from './admin.service';

@Controller('admin')
export class AdminController {
    constructor(private adminService: AdminService) { }

    // ─── ADMIN AUTH ──────────────────────────────────────

    @Post('signup')
    async signup(@Body() body: { email: string; password: string; name: string }) {
        return this.adminService.signup(body.email, body.password, body.name);
    }

    @Post('login')
    async login(@Body() body: { email: string; password: string }) {
        return this.adminService.login(body.email, body.password);
    }

    // ─── DASHBOARD STATS ────────────────────────────────

    @Get('stats')
    async getStats() {
        return this.adminService.getDashboardStats();
    }

    @Get('recent-activity')
    async getRecentActivity() {
        return this.adminService.getRecentActivity();
    }

    // ─── USERS ──────────────────────────────────────────

    @Get('users')
    async getUsers(@Query('role') role?: string) {
        return this.adminService.getUsers(role);
    }

    // ─── TRIPS ──────────────────────────────────────────

    @Get('trips')
    async getTrips(@Query('status') status?: string) {
        return this.adminService.getTrips(status);
    }

    // ─── PAYMENTS ───────────────────────────────────────

    @Get('payments')
    async getPayments() {
        return this.adminService.getPayments();
    }

    @Get('payment-stats')
    async getPaymentStats() {
        return this.adminService.getPaymentStats();
    }

    // ─── DOCUMENTS ──────────────────────────────────────

    @Get('documents')
    async getDocuments() {
        return this.adminService.getDocuments();
    }

    @Post('documents/:id/review')
    async reviewDocument(
        @Param('id') id: string,
        @Body() body: { status: 'approved' | 'rejected'; notes?: string },
    ) {
        return this.adminService.reviewDocument(id, body.status, body.notes);
    }

    // ─── COMPLAINTS ─────────────────────────────────────

    @Get('complaints')
    async getComplaints() {
        return this.adminService.getComplaints();
    }

    // ─── DEVELOPER ──────────────────────────────────────

    @Post('developer/login')
    async developerLogin(@Body() body: { email: string; password: string }) {
        return this.adminService.developerLogin(body.email, body.password);
    }

    @Get('developer/stats')
    async getDeveloperStats() {
        return this.adminService.getDeveloperStats();
    }
}
