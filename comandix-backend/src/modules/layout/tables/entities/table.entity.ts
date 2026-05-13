import {
  Entity, PrimaryGeneratedColumn, Column,
  ManyToOne, JoinColumn, UpdateDateColumn,
} from 'typeorm';
import { Restaurant } from '../../../restaurants/entities/restaurant.entity';
import { Sector } from '../../sectors/entities/sector.entity';

export type TableStatus = 'free' | 'occupied' | 'waiting_payment' | 'ready';
export type TableShape = 'square' | 'rectangle' | 'circle';

@Entity('tables')
export class Table {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @ManyToOne(() => Restaurant, (r) => r.tables)
  @JoinColumn({ name: 'restaurantId' })
  restaurant: Restaurant;

  @Column()
  sectorId: string;

  @ManyToOne(() => Sector, (s) => s.tables)
  @JoinColumn({ name: 'sectorId' })
  sector: Sector;

  @Column()
  name: string;

  @Column({ default: 4 })
  capacity: number;

  @Column({ type: 'varchar', default: 'square' })
  shape: TableShape;

  @Column({ type: 'float', default: 100 })
  posX: number;

  @Column({ type: 'float', default: 100 })
  posY: number;

  @Column({ type: 'float', default: 80 })
  width: number;

  @Column({ type: 'float', default: 80 })
  height: number;

  @Column({ type: 'float', default: 0 })
  rotation: number;

  @Column({ type: 'varchar', default: 'free' })
  status: TableStatus;

  @Column({ type: 'varchar', default: 'table' })
  type: string; // 'table', 'wall', 'decoration', 'label'

  @Column({ type: 'varchar', nullable: true })
  icon: string;

  @Column({ type: 'varchar', nullable: true })
  color: string;

  @Column({ type: 'varchar', nullable: true })
  labelText: string;

  @Column({ type: 'int', default: 0 })
  zIndex: number;

  @UpdateDateColumn()
  updatedAt: Date;
}
