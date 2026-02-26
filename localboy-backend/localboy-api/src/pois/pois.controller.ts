import { Controller, Get, Query } from '@nestjs/common';
import { PoisService } from './pois.service';

@Controller('pois')
export class PoisController {
  constructor(private poisService: PoisService) {}

  @Get()
  async findAll(@Query('city') city?: string) {
    return this.poisService.findAll(city);
  }
}
