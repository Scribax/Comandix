import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductCategory } from './entities/category.entity';

@Injectable()
export class CategoriesService {
  constructor(@InjectRepository(ProductCategory) private readonly repo: Repository<ProductCategory>) {}
  findAll(restaurantId: string) { return this.repo.find({ where: { restaurantId }, order: { sortOrder: 'ASC' } }); }
  create(restaurantId: string, data: Partial<ProductCategory>) { return this.repo.save(this.repo.create({ ...data, restaurantId })); }
  update(id: string, data: Partial<ProductCategory>) { return this.repo.update(id, data); }
  remove(id: string) { return this.repo.delete(id); }
}
