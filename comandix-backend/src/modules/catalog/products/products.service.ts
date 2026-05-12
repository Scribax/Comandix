import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './entities/product.entity';

@Injectable()
export class ProductsService {
  constructor(@InjectRepository(Product) private readonly repo: Repository<Product>) {}
  findAll(restaurantId: string) { return this.repo.find({ where: { restaurantId }, relations: ['category'] }); }
  create(restaurantId: string, data: Partial<Product>) { return this.repo.save(this.repo.create({ ...data, restaurantId })); }
  update(id: string, data: Partial<Product>) { return this.repo.update(id, data); }
  remove(id: string) { return this.repo.delete(id); }
}
