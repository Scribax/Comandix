import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Table } from './entities/table.entity';

@Injectable()
export class TablesService {
  constructor(@InjectRepository(Table) private readonly repo: Repository<Table>) {}
  findAll(restaurantId: string) { return this.repo.find({ where: { restaurantId }, relations: ['sector'] }); }
  findOne(restaurantId: string, id: string) { return this.repo.findOne({ where: { id, restaurantId } }); }
  create(restaurantId: string, data: Partial<Table>) { return this.repo.save(this.repo.create({ ...data, restaurantId })); }
  update(id: string, data: Partial<Table>) { return this.repo.update(id, data); }
  
  async bulkUpdate(restaurantId: string, data: Partial<Table>[]) {
    const tables = data.map(t => this.repo.create({ ...t, restaurantId }));
    return this.repo.save(tables);
  }

  remove(id: string) { return this.repo.delete(id); }
}
