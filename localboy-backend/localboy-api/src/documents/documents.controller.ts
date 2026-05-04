import {
    Controller,
    Post,
    Get,
    Param,
    Body,
    UseGuards,
    Request,
    UseInterceptors,
    UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AuthGuard } from '@nestjs/passport';
import { Request as ExpressRequest } from 'express';
import { DocumentsService } from './documents.service';
import { User } from '../entities/user.entity';
import { UnauthorizedException } from '@nestjs/common';
import { DocumentType } from '../entities/document.entity';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';

// Ensure uploads directory exists
const uploadsDir = join(process.cwd(), 'uploads', 'documents');
if (!existsSync(uploadsDir)) {
    mkdirSync(uploadsDir, { recursive: true });
}

@Controller('documents')
export class DocumentsController {
    constructor(private documentsService: DocumentsService) { }

    /**
     * Upload a document with actual file
     * POST /api/documents/upload-file
     */
    @Post('upload-file')
    @UseGuards(AuthGuard('jwt'))
    @UseInterceptors(
        FileInterceptor('file', {
            storage: diskStorage({
                destination: uploadsDir,
                filename: (_req, file, cb) => {
                    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
                    const ext = extname(file.originalname);
                    cb(null, `doc-${uniqueSuffix}${ext}`);
                },
            }),
            limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
            fileFilter: (_req, file, cb) => {
                const allowed = /\.(jpg|jpeg|png|pdf|doc|docx)$/i;
                if (allowed.test(extname(file.originalname))) {
                    cb(null, true);
                } else {
                    cb(new Error('Only images and documents are allowed'), false);
                }
            },
        }),
    )
    async uploadFile(
        @Request() req: ExpressRequest & { user?: User },
        @UploadedFile() file: Express.Multer.File,
        @Body() body: { doc_type: DocumentType },
    ) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();
        if (!file) throw new Error('No file uploaded');

        const fileUrl = `/uploads/documents/${file.filename}`;
        return this.documentsService.upload(userId, body.doc_type, fileUrl, file.originalname);
    }

    /**
     * Upload document metadata (URL-based, for when file is already hosted)
     * POST /api/documents/upload
     */
    @Post('upload')
    @UseGuards(AuthGuard('jwt'))
    async upload(
        @Request() req: ExpressRequest & { user?: User },
        @Body()
        body: {
            doc_type: DocumentType;
            file_url: string;
            file_name: string;
        },
    ) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        return this.documentsService.upload(userId, body.doc_type, body.file_url, body.file_name);
    }

    @Get('my-documents')
    @UseGuards(AuthGuard('jwt'))
    async getMyDocuments(@Request() req: ExpressRequest & { user?: User }) {
        const userId = req.user?.id;
        if (!userId) throw new UnauthorizedException();

        return this.documentsService.getByUser(userId);
    }

    @Get('pending')
    async getPending() {
        return this.documentsService.getPending();
    }

    @Get('all')
    async getAll() {
        return this.documentsService.getAll();
    }

    @Post(':id/review')
    async review(
        @Body() body: { status: 'approved' | 'rejected'; notes?: string },
        @Param('id') id: string,
    ) {
        return this.documentsService.review(id, 'admin', body.status, body.notes);
    }
}
