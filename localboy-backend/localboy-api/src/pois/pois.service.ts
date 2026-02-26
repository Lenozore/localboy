import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Poi } from '../entities/poi.entity';

@Injectable()
export class PoisService {
  constructor(
    @InjectRepository(Poi)
    private poisRepository: Repository<Poi>,
  ) {}

  async findAll(city?: string) {
    const where: Record<string, any> = { is_active: true };
    
    if (city) {
      where.city = city;
    }

    return this.poisRepository.find({
      where,
      order: { priority: 'DESC' },
    });
  }

  async findOne(id: string) {
    return this.poisRepository.findOne({ where: { id } });
  }

  async selectPoisForBooking(
    hotelLat: number,
    hotelLng: number,
    city: string,
    packageType: string,
  ) {
    const allPois = await this.poisRepository.find({
      where: { city, is_active: true },
      order: { priority: 'DESC' },
    });

    const count = packageType === 'full_day' ? 4 : 3;
    return allPois.slice(0, count);
  }
}
