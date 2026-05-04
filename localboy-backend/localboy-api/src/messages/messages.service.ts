import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from '../entities/message.entity';

@Injectable()
export class MessagesService {
    private readonly logger = new Logger(MessagesService.name);

    constructor(
        @InjectRepository(Message)
        private messagesRepository: Repository<Message>,
    ) { }

    async send(
        tripId: string,
        senderId: string,
        receiverId: string,
        content: string,
    ): Promise<Message> {
        const message = this.messagesRepository.create({
            trip_id: tripId,
            sender_id: senderId,
            receiver_id: receiverId,
            content,
        });
        return this.messagesRepository.save(message);
    }

    async getByTrip(tripId: string): Promise<Message[]> {
        return this.messagesRepository.find({
            where: { trip_id: tripId },
            relations: ['sender', 'receiver'],
            order: { created_at: 'ASC' },
        });
    }

    async markAsRead(messageId: string, userId: string): Promise<void> {
        await this.messagesRepository.update(
            { id: messageId, receiver_id: userId },
            { is_read: true },
        );
    }

    async getUnreadCount(userId: string): Promise<number> {
        return this.messagesRepository.count({
            where: { receiver_id: userId, is_read: false },
        });
    }
}
