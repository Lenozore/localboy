import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Poi } from '../entities/poi.entity';

@Injectable()
export class PoisService {
  constructor(
    @InjectRepository(Poi)
    private poisRepository: Repository<Poi>,
  ) { }

  async findAll(city?: string): Promise<Poi[]> {
    const where: Record<string, unknown> = { is_active: true };

    if (city) {
      where.city = city;
    }

    return this.poisRepository.find({
      where,
      order: { popularity_score: 'DESC' },
    });
  }

  async findNearby(lat: number, lng: number, radiusKm = 50): Promise<Poi[]> {
    const allPois = await this.poisRepository.find({
      where: { is_active: true },
    });

    // Filter by distance and sort by distance + popularity
    const poisWithDistance = allPois
      .map((poi) => ({
        ...poi,
        distance_km: this.haversineDistance(lat, lng, Number(poi.lat), Number(poi.lng)),
      }))
      .filter((poi) => poi.distance_km <= radiusKm)
      .sort((a, b) => {
        // Weighted sort: popularity * 0.6 + proximity * 0.4
        const scoreA = a.popularity_score * 0.6 + (1 / (a.distance_km + 1)) * 40;
        const scoreB = b.popularity_score * 0.6 + (1 / (b.distance_km + 1)) * 40;
        return scoreB - scoreA;
      });

    return poisWithDistance;
  }

  async findOne(id: string): Promise<Poi | null> {
    return this.poisRepository.findOne({ where: { id } });
  }

  async selectPoisForTrip(
    hotelLat: number,
    hotelLng: number,
    city: string,
    tripType: string,
  ): Promise<Poi[]> {
    const allPois = await this.poisRepository.find({
      where: { city, is_active: true },
    });

    const poisWithDistance = allPois.map((poi) => ({
      poi,
      distance: this.haversineDistance(hotelLat, hotelLng, Number(poi.lat), Number(poi.lng)),
    }));

    poisWithDistance.sort((a, b) => {
      if (b.poi.popularity_score !== a.poi.popularity_score) {
        return b.poi.popularity_score - a.poi.popularity_score;
      }
      return a.distance - b.distance;
    });

    const count = tripType === 'full_day' ? 5 : 3;
    return poisWithDistance.slice(0, count).map((item) => item.poi);
  }

  private haversineDistance(
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number,
  ): number {
    const R = 6371;
    const dLat = this.toRadians(lat2 - lat1);
    const dLng = this.toRadians(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRadians(lat1)) *
      Math.cos(this.toRadians(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }
}
