import {
  Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, JoinColumn,
} from 'typeorm';
import { Restaurant } from '../../../restaurants/entities/restaurant.entity';
import { Table } from '../../tables/entities/table.entity';

@Entity('sectors')
export class Sector {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  restaurantId: string;

  @ManyToOne(() => Restaurant, (r) => r.sectors)
  @JoinColumn({ name: 'restaurantId' })
  restaurant: Restaurant;

  @Column()
  name: string;

  @Column({ default: '#3498DB' })
  color: string;

  @OneToMany(() => Table, (t) => t.sector)
  tables: Table[];
}
