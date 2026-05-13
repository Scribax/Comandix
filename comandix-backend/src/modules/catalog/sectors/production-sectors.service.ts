import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductionSector } from './entities/production-sector.entity';

@Injectable()
export class ProductionSectorsService {
  constructor(
    @InjectRepository(ProductionSector)
    private sectorsRepository: Repository<ProductionSector>,
  ) {}

  findAllByRestaurant(restaurantId: string): Promise<ProductionSector[]> {
    return this.sectorsRepository.find({
      where: { restaurantId },
    });
  }

  async create(restaurantId: string, name: string, icon: string): Promise<ProductionSector> {
    const sector = this.sectorsRepository.create({
      restaurantId,
      name,
      icon,
    });
    return this.sectorsRepository.save(sector);
  }

  async update(id: string, name: string, icon: string): Promise<ProductionSector> {
    await this.sectorsRepository.update(id, { name, icon });
    const updated = await this.sectorsRepository.findOneBy({ id });
    if (!updated) throw new NotFoundException('Sector no encontrado');
    return updated;
  }

  async delete(id: string): Promise<void> {
    await this.sectorsRepository.delete(id);
  }
}
