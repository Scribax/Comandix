import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { ProductCategory } from '../categories/entities/category.entity';

@Entity('production_sectors')
export class ProductionSector {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @ManyToOne(() => Restaurant)
  @JoinColumn({ name: 'restaurantId' })
  restaurant: Restaurant;

  @Column()
  name: string;

  @Column({ default: 'kitchen' })
  icon: string;

  @OneToMany(() => ProductCategory, (category) => category.productionSector)
  categories: ProductCategory[];
}
