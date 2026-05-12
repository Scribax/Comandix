import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity';
import { Table } from '../layout/tables/entities/table.entity';
import { PrintersService } from '../printers/printers.service';
import { OrdersGateway } from './orders.gateway';

export class CreateOrderDto {
  tableId: string;
  terminalId?: string;
  items: { productId: string; quantity: number; unitPrice: number; productNameSnapshot: string; notes?: string }[];
}

export class AddItemDto {
  productId: string;
  quantity: number;
  unitPrice: number;
  productNameSnapshot: string;
  notes?: string;
}

export class CloseOrderDto {
  paymentMethod: 'cash' | 'card' | 'qr';
}

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly ordersRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly itemsRepo: Repository<OrderItem>,
    @InjectRepository(Table)
    private readonly tablesRepo: Repository<Table>,
    private readonly printersService: PrintersService,
    private readonly gateway: OrdersGateway,
  ) {}

  async openTable(restaurantId: string, userId: string, dto: CreateOrderDto) {
    const table = await this.tablesRepo.findOne({
      where: { id: dto.tableId, restaurantId },
    });
    if (!table) throw new NotFoundException('Table not found');

    const order = this.ordersRepo.create({
      restaurantId,
      tableId: dto.tableId,
      terminalId: dto.terminalId,
      userId,
      status: 'open',
    });
    const saved = await this.ordersRepo.save(order);

    if (dto.items && dto.items.length > 0) {
      const orderItems = dto.items.map(item => this.itemsRepo.create({
        orderId: saved.id,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        productNameSnapshot: item.productNameSnapshot,
        notes: item.notes,
      }));
      await this.itemsRepo.save(orderItems);
    }

    table.status = 'occupied';
    await this.tablesRepo.save(table);

    this.gateway.emitTableUpdate(restaurantId, table);
    return this.getOrderById(restaurantId, saved.id);
  }

  async addItemsToOrder(restaurantId: string, orderId: string, items: AddItemDto[]) {
    const order = await this.ordersRepo.findOne({ where: { id: orderId, restaurantId } });
    if (!order) throw new NotFoundException('Order not found');

    const orderItems = items.map(item => this.itemsRepo.create({
      orderId: order.id,
      productId: item.productId,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      productNameSnapshot: item.productNameSnapshot,
      notes: item.notes,
    }));
    
    await this.itemsRepo.save(orderItems);
    this.gateway.emitOrderUpdated(restaurantId, orderId);
    return this.getOrderById(restaurantId, order.id);
  }

  async sendToKitchen(restaurantId: string, orderId: string) {
    const order = await this.ordersRepo.findOne({
      where: { id: orderId, restaurantId },
      relations: ['items', 'items.product', 'items.product.category', 'table', 'user'],
    });
    if (!order) throw new NotFoundException('Order not found');

    await this.printersService.routeAndPrint(restaurantId, order);
    this.gateway.emitNewKitchenOrder(restaurantId, order);
    return { message: 'Order sent to kitchen' };
  }

  async closeOrder(restaurantId: string, orderId: string, dto: CloseOrderDto) {
    const order = await this.ordersRepo.findOne({
      where: { id: orderId, restaurantId },
      relations: ['items'],
    });
    if (!order) throw new NotFoundException('Order not found');

    const subtotal = order.items.reduce((s, i) => s + i.unitPrice * i.quantity, 0);
    const tax = subtotal * 0.21;

    order.status = 'closed';
    order.paymentMethod = dto.paymentMethod;
    order.subtotal = subtotal;
    order.tax = tax;
    order.total = subtotal + tax;
    order.closedAt = new Date();
    await this.ordersRepo.save(order);

    const table = await this.tablesRepo.findOne({ where: { id: order.tableId } });
    if (table) {
      table.status = 'free';
      await this.tablesRepo.save(table);
      this.gateway.emitTableUpdate(restaurantId, table);
    }

    return order;
  }

  async getOpenOrders(restaurantId: string) {
    return this.ordersRepo.find({
      where: { restaurantId, status: 'open' },
      relations: ['items', 'table', 'user'],
      order: { createdAt: 'DESC' },
    });
  }

  async getOrderById(restaurantId: string, orderId: string) {
    const order = await this.ordersRepo.findOne({
      where: { id: orderId, restaurantId },
      relations: ['items', 'items.product', 'table', 'user'],
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }
}
