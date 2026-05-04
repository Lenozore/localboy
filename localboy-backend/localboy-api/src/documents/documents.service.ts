import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Document, DocumentStatus, DocumentType } from '../entities/document.entity';

@Injectable()
export class DocumentsService {
    private readonly logger = new Logger(DocumentsService.name);

    constructor(
        @InjectRepository(Document)
        private documentsRepository: Repository<Document>,
    ) { }

    async upload(
        userId: string,
        docType: DocumentType,
        fileUrl: string,
        fileName: string,
    ): Promise<Document> {
        const doc = this.documentsRepository.create({
            user_id: userId,
            doc_type: docType,
            file_url: fileUrl,
            file_name: fileName,
            status: 'pending',
        });

        return this.documentsRepository.save(doc);
    }

    async getByUser(userId: string): Promise<Document[]> {
        return this.documentsRepository.find({
            where: { user_id: userId },
            order: { uploaded_at: 'DESC' },
        });
    }

    async getPending(): Promise<Document[]> {
        return this.documentsRepository.find({
            where: { status: 'pending' },
            relations: ['user'],
            order: { uploaded_at: 'ASC' },
        });
    }

    async getAll(): Promise<Document[]> {
        return this.documentsRepository.find({
            relations: ['user'],
            order: { uploaded_at: 'DESC' },
        });
    }

    async review(
        docId: string,
        reviewerId: string,
        status: 'approved' | 'rejected',
        notes?: string,
    ): Promise<Document> {
        const doc = await this.documentsRepository.findOne({ where: { id: docId } });
        if (!doc) throw new Error('Document not found');

        doc.status = status;
        doc.reviewed_by = reviewerId;
        doc.review_notes = notes ?? undefined as unknown as string;
        doc.reviewed_at = new Date();

        return this.documentsRepository.save(doc);
    }
}
