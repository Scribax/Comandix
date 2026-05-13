import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not, In } from 'typeorm';
import { Order, OrderStatus } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity';
import { Table } from '../layout/tables/entities/table.entity';
import { PrintersService } from '../printers/printers.service';
import { OrdersGateway } from './orders.gateway';

import { IsString, IsUUID, IsOptional, IsArray, IsEnum, IsNumber } from 'class-validator';

export class CreateOrderDto {
  @IsUUID()
  tableId: string;

  @IsOptional()
  @IsString()
  terminalId?: string;

  @IsOptional()
  @IsArray()
  items?: AddItemDto[];
}

export class AddItemDto {
  @IsUUID()
  productId: string;

  @IsNumber()
  quantity: number;

  @IsNumber()
  unitPriceSnapshot: number;

  @IsString()
  productNameSnapshot: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateOrderStatusDto {
  @IsEnum(OrderStatus)
  status: OrderStatus;
}

export class CloseOrderDto {
  @IsEnum(['cash', 'card', 'qr'])
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

  async openTable(restaurantId: string, waiterId: string, dto: CreateOrderDto) {
    const table = await this.tablesRepo.findOne({
      where: { id: dto.tableId, restaurantId },
    });
    if (!table) throw new NotFoundException('Mesa no encontrada');

    const order = this.ordersRepo.create({
      restaurantId,
      tableId: dto.tableId,
      terminalId: dto.terminalId,
      userId: waiterId, // Note: We keep userId in DB for now to avoid breaking too much, but it represents the waiter
      status: OrderStatus.DRAFT,
    });
    const saved = await this.ordersRepo.save(order);

    if (dto.items && dto.items.length > 0) {
      await this.addItemsToOrder(restaurantId, saved.id, dto.items);
    }

    table.status = 'occupied';
    await this.tablesRepo.save(table);

    this.gateway.emitTableUpdate(restaurantId, table);
    return this.getOrderById(restaurantId, saved.id);
  }

  async addItemsToOrder(restaurantId: string, orderId: string, items: AddItemDto[]) {
    const order = await this.ordersRepo.findOne({ where: { id: orderId, restaurantId } });
    if (!order) throw new NotFoundException('Pedido no encontrado');

    const orderItems = items.map(item => this.itemsRepo.create({
      orderId: order.id,
      productId: item.productId,
      quantity: item.quantity,
      unitPriceSnapshot: item.unitPriceSnapshot,
      productNameSnapshot: item.productNameSnapshot,
      notes: item.notes,
    }));
    
    await this.itemsRepo.save(orderItems);
    await this.updateOrderTotals(restaurantId, order.id);
    
    this.gateway.emitOrderUpdated(restaurantId, order);
    return this.getOrderById(restaurantId, order.id);
  }

  async updateStatus(restaurantId: string, orderId: string, status: OrderStatus) {
    const order = await this.getOrderById(restaurantId, orderId);
    
    order.status = status;
    
    if (status === OrderStatus.SENT_TO_KITCHEN) {
      await this.printersService.routeAndPrint(restaurantId, order);
      this.gateway.emitNewKitchenOrder(restaurantId, order);
    }

    if (status === OrderStatus.READY) {
      const table = await this.tablesRepo.findOne({ where: { id: order.tableId } });
      if (table) {
        table.status = 'ready';
        await this.tablesRepo.save(table);
        this.gateway.emitTableUpdate(restaurantId, table);
      }
    }

    if (status === OrderStatus.CANCELLED) {
      const table = await this.tablesRepo.findOne({ where: { id: order.tableId } });
      if (table) {
        table.status = 'free';
        await this.tablesRepo.save(table);
        this.gateway.emitTableUpdate(restaurantId, table);
      }
    }

    return this.ordersRepo.save(order);
  }

  async closeOrder(restaurantId: string, orderId: string, dto: CloseOrderDto) {
    const order = await this.ordersRepo.findOne({
      where: { id: orderId, restaurantId },
      relations: ['items'],
    });
    if (!order) throw new NotFoundException('Pedido no encontrado');

    await this.updateOrderTotals(restaurantId, order.id);
    
    order.status = OrderStatus.PAID;
    order.paymentMethod = dto.paymentMethod;
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

  private async updateOrderTotals(restaurantId: string, orderId: string) {
    const order = await this.ordersRepo.findOne({
      where: { id: orderId, restaurantId },
      relations: ['items'],
    });
    if (!order) return;

    // Subtotal ignores voided items
    const subtotal = order.items
      .filter(i => !i.isVoided)
      .reduce((s, i) => s + Number(i.unitPriceSnapshot) * i.quantity, 0);
      
    order.subtotal = subtotal;
    order.total = subtotal; // For now total = subtotal, can add tax logic later if needed
    await this.ordersRepo.save(order);
  }

  async voidItem(restaurantId: string, orderId: string, itemId: string) {
    const order = await this.ordersRepo.findOne({
      where: { id: orderId, restaurantId },
      relations: ['items', 'items.product', 'table', 'user'],
    });
    if (!order) throw new NotFoundException('Pedido no encontrado');

    const item = order.items.find(i => i.id === itemId);
    if (!item) throw new NotFoundException('Ítem no encontrado en el pedido');
    
    if (item.isVoided) return order;

    item.isVoided = true;
    await this.itemsRepo.save(item);

    // Si ya estaba enviado a la cocina, imprimimos ticket de anulación
    if (order.status !== OrderStatus.DRAFT) {
      await this.printersService.printVoidTicket(restaurantId, order, item);
      this.logger.log(`[VOID TICKET] Enviada anulación de ${item.quantity}x ${item.productNameSnapshot} para la Mesa ${order.tableId}`);
    }

    await this.updateOrderTotals(restaurantId, order.id);
    this.gateway.emitOrderUpdated(restaurantId, order);
    
    return this.getOrderById(restaurantId, order.id);
  }

  async getActiveOrders(restaurantId: string) {
    return this.ordersRepo.find({
      where: { 
        restaurantId, 
        status: Not(In([OrderStatus.PAID, OrderStatus.CANCELLED])) 
      } as any,
      relations: ['items', 'table', 'user'],
      order: { createdAt: 'DESC' },
    });
  }

  async getOrderById(restaurantId: string, orderId: string) {
    const order = await this.ordersRepo.findOne({
      where: { id: orderId, restaurantId },
      relations: ['items', 'items.product', 'table', 'user'],
    });
    if (!order) throw new NotFoundException('Pedido no encontrado');
    return order;
  }

  async deleteOrder(restaurantId: string, orderId: string) {
    const order = await this.getOrderById(restaurantId, orderId);
    
    // Release table if active
    if (order.status !== OrderStatus.PAID && order.status !== OrderStatus.CANCELLED) {
      const table = await this.tablesRepo.findOne({ where: { id: order.tableId } });
      if (table) {
        table.status = 'free';
        await this.tablesRepo.save(table);
      }
    }
    
    return this.ordersRepo.remove(order);
  }

  async getDashboardStats(restaurantId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    // 1. Get Today's Sales & Orders
    const todayOrders = await this.ordersRepo.find({
      where: {
        restaurantId,
        status: OrderStatus.PAID,
      }
    });
    
    // Filter by date manually to be safe with DB timezones
    const todayPaidOrders = todayOrders.filter(o => o.closedAt && o.closedAt >= today && o.closedAt < tomorrow);
    const yesterdayPaidOrders = todayOrders.filter(o => o.closedAt && o.closedAt >= yesterday && o.closedAt < today);

    const salesToday = todayPaidOrders.reduce((sum, o) => sum + Number(o.total), 0);
    const salesYesterday = yesterdayPaidOrders.reduce((sum, o) => sum + Number(o.total), 0);
    const ordersCount = todayPaidOrders.length;

    // 2. Occupation
    const tables = await this.tablesRepo.find({ where: { restaurantId } });
    const totalTables = tables.length;
    const occupiedTables = tables.filter(t => t.status === 'occupied').length;
    const occupationPercent = totalTables > 0 ? (occupiedTables / totalTables) * 100 : 0;

    // 3. Sales By Hour (Today)
    const salesByHour = Array(12).fill(0).map((_, i) => ({ hour: 12 + i, total: 0 })); 
    todayPaidOrders.forEach(o => {
      const hour = o.closedAt.getHours();
      const slot = salesByHour.find(s => s.hour === hour);
      if (slot) slot.total += Number(o.total);
    });

    // 4. Top Products
    const productMap = new Map<string, { name: string, count: number }>();
    const allItems = await this.itemsRepo.find({
      where: { orderId: In(todayPaidOrders.map(o => o.id)) }
    });

    allItems.forEach(item => {
      const existing = productMap.get(item.productId) || { name: item.productNameSnapshot, count: 0 };
      existing.count += item.quantity;
      productMap.set(item.productId, existing);
    });

    const topProducts = Array.from(productMap.values())
      .sort((a, b) => b.count - a.count)
      .slice(0, 4);

    return {
      salesToday,
      salesYesterday,
      ordersCount,
      occupationPercent,
      salesByHour,
      topProducts
    };
  }
}
