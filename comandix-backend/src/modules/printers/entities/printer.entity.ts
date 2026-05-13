import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany,
} from 'typeorm';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { PrinterRoute } from './printer-route.entity';

export type PrinterType = 'LAN' | 'INTERNET';

@Entity('printers')
export class Printer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @ManyToOne(() => Restaurant, (r) => r.printers)
  @JoinColumn({ name: 'restaurantId' })
  restaurant: Restaurant;

  @Column()
  name: string;

  @Column({ type: 'varchar' })
  type: PrinterType;

  // LAN printer fields
  @Column({ nullable: true })
  ipAddress: string;

  @Column({ nullable: true, type: 'int' })
  port: number;

  // Internet printer fields
  @Column({ nullable: true })
  endpointUrl: string;

  @Column({ nullable: true })
  token: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  productionSectorId: string;

  @OneToMany(() => PrinterRoute, (pr) => pr.printer)
  routes: PrinterRoute[];
}
