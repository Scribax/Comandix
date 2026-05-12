import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn,
} from 'typeorm';
import { Printer } from './printer.entity';
import { ProductCategory } from '../../catalog/categories/entities/category.entity';

@Entity('printer_routes')
export class PrinterRoute {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @Column()
  categoryId: string;

  @ManyToOne(() => ProductCategory, (c) => c.printerRoutes)
  @JoinColumn({ name: 'categoryId' })
  category: ProductCategory;

  @Column()
  printerId: string;

  @ManyToOne(() => Printer, (p) => p.routes)
  @JoinColumn({ name: 'printerId' })
  printer: Printer;
}
