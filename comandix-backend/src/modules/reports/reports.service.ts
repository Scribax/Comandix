import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Order, OrderStatus } from '../orders/entities/order.entity';
import { OrderItem } from '../orders/entities/order-item.entity';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Order) private readonly ordersRepo: Repository<Order>,
    @InjectRepository(OrderItem) private readonly itemsRepo: Repository<OrderItem>,
  ) {}

  async getDailySales(restaurantId: string, date: string) {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const orders = await this.ordersRepo.find({
      where: { restaurantId, status: OrderStatus.PAID, closedAt: Between(start, end) } as any,
    });

    const totalSales = orders.reduce((sum, o) => sum + o.total, 0);
    const byMethod = {
      cash: orders.filter((o) => o.paymentMethod === 'cash').reduce((s, o) => s + o.total, 0),
      card: orders.filter((o) => o.paymentMethod === 'card').reduce((s, o) => s + o.total, 0),
      qr: orders.filter((o) => o.paymentMethod === 'qr').reduce((s, o) => s + o.total, 0),
    };

    return { date, totalSales, totalOrders: orders.length, byMethod };
  }
}
