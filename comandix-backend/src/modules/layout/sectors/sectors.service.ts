import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Sector } from './entities/sector.entity';

@Injectable()
export class SectorsService {
  constructor(@InjectRepository(Sector) private readonly repo: Repository<Sector>) {}
  findAll(restaurantId: string) { return this.repo.find({ where: { restaurantId }, relations: ['tables'] }); }
  create(restaurantId: string, data: Partial<Sector>) { return this.repo.save(this.repo.create({ ...data, restaurantId })); }
  update(id: string, data: Partial<Sector>) { return this.repo.update(id, data); }
  remove(id: string) { return this.repo.delete(id); }
}
