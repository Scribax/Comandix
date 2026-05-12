import {
  Entity, PrimaryGeneratedColumn, Column,
  CreateDateColumn, UpdateDateColumn, OneToMany,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Sector } from '../../layout/sectors/entities/sector.entity';
import { Table } from '../../layout/tables/entities/table.entity';
import { ProductCategory } from '../../catalog/categories/entities/category.entity';
import { Product } from '../../catalog/products/entities/product.entity';
import { Printer } from '../../printers/entities/printer.entity';
import { Order } from '../../orders/entities/order.entity';

@Entity('restaurants')
export class Restaurant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  slug: string;

  @Column({ default: 'America/Argentina/Buenos_Aires' })
  timezone: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => User, (u) => u.restaurant)
  users: User[];

  @OneToMany(() => Sector, (s) => s.restaurant)
  sectors: Sector[];

  @OneToMany(() => Table, (t) => t.restaurant)
  tables: Table[];

  @OneToMany(() => ProductCategory, (c) => c.restaurant)
  categories: ProductCategory[];

  @OneToMany(() => Product, (p) => p.restaurant)
  products: Product[];

  @OneToMany(() => Printer, (p) => p.restaurant)
  printers: Printer[];

  @OneToMany(() => Order, (o) => o.restaurant)
  orders: Order[];
}
