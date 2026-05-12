import {
  Entity, PrimaryGeneratedColumn, Column,
  ManyToOne, JoinColumn, CreateDateColumn,
} from 'typeorm';
import { Restaurant } from '../../../restaurants/entities/restaurant.entity';
import { ProductCategory } from '../../categories/entities/category.entity';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @ManyToOne(() => Restaurant, (r) => r.products)
  @JoinColumn({ name: 'restaurantId' })
  restaurant: Restaurant;

  @Column()
  categoryId: string;

  @ManyToOne(() => ProductCategory, (c) => c.products)
  @JoinColumn({ name: 'categoryId' })
  category: ProductCategory;

  @Column()
  name: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price: number;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
