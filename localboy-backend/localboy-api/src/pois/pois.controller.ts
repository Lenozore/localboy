import { Controller, Get, Query } from '@nestjs/common';
import { PoisService } from './pois.service';
import { Poi } from '../entities/poi.entity';

@Controller('pois')
export class PoisController {
  constructor(private poisService: PoisService) { }

  @Get()
  async findAll(@Query('city') city?: string): Promise<Poi[]> {
    return this.poisService.findAll(city);
  }

  @Get('nearby')
  async findNearby(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius?: string,
  ) {
    return this.poisService.findNearby(
      parseFloat(lat),
      parseFloat(lng),
      radius ? parseFloat(radius) : undefined,
    );
  }
}
