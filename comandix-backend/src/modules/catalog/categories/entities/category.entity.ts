import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany,
} from 'typeorm';
import { Restaurant } from '../../../restaurants/entities/restaurant.entity';
import { Product } from '../../products/entities/product.entity';
import { ProductionSector } from '../../sectors/entities/production-sector.entity';
import { PrinterRoute } from '../../../printers/entities/printer-route.entity';

@Entity('product_categories')
export class ProductCategory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @ManyToOne(() => Restaurant, (r) => r.categories)
  @JoinColumn({ name: 'restaurantId' })
  restaurant: Restaurant;

  @Column()
  name: string;

  @Column({ default: 'category' })
  icon: string;

  @Column({ default: '#9B59B6' })
  color: string;

  @Column({ default: 0 })
  sortOrder: number;

  @OneToMany(() => Product, (p) => p.category)
  products: Product[];

  @Column({ nullable: true })
  productionSectorId: string;

  @ManyToOne(() => ProductionSector, (sector) => sector.categories)
  @JoinColumn({ name: 'productionSectorId' })
  productionSector: ProductionSector;

  @OneToMany(() => PrinterRoute, (pr) => pr.category)
  printerRoutes: PrinterRoute[];
}
