import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';
import { Printer } from './entities/printer.entity';
import { PrinterRoute } from './entities/printer-route.entity';
import { Order } from '../orders/entities/order.entity';
import { OrderItem } from '../orders/entities/order-item.entity';

@Injectable()
export class PrintersService {
  private readonly logger = new Logger(PrintersService.name);

  constructor(
    @InjectRepository(Printer)
    private readonly printersRepo: Repository<Printer>,
    @InjectRepository(PrinterRoute)
    private readonly routesRepo: Repository<PrinterRoute>,
    private readonly http: HttpService,
  ) {}

  async findAll(restaurantId: string) {
    return this.printersRepo.find({ where: { restaurantId } });
  }

  async routeAndPrint(restaurantId: string, order: Order) {
    // 1. Load active routes for this restaurant
    const routes = await this.routesRepo.find({
      where: { restaurantId },
      relations: ['printer'],
    });

    // 2. Build categoryId → Printer map
    const categoryPrinterMap = new Map<string, Printer>();
    routes.forEach((r) => {
      if (r.printer?.isActive) categoryPrinterMap.set(r.categoryId, r.printer);
    });

    // 3. Group items by printer
    const jobs = new Map<string, { printer: Printer; items: OrderItem[] }>();
    for (const item of order.items) {
      const catId = (item.product as any)?.categoryId;
      const printer = categoryPrinterMap.get(catId);
      if (!printer) continue;
      if (!jobs.has(printer.id)) jobs.set(printer.id, { printer, items: [] });
      jobs.get(printer.id)!.items.push(item);
    }

    // 4. Dispatch jobs
    for (const { printer, items } of jobs.values()) {
      const ticket = this.buildTicket(order, items);
      if (printer.type === 'INTERNET') {
        await this.sendInternet(printer, ticket);
      } else {
        // LAN: handled by the Desktop App locally
        this.logger.log(`[LAN] Print job for ${printer.name} queued for local dispatch.`);
      }
    }
  }

  private buildTicket(order: Order, items: OrderItem[]): string {
    const time = new Date().toTimeString().substring(0, 5);
    const lines = [
      '--------------------------------',
      `TABLE : ${(order.table as any)?.name ?? order.tableId}`,
      `WAITER: ${(order.user as any)?.name ?? 'N/A'}`,
      `TIME  : ${time}`,
      '--------------------------------',
      ...items.map((i) => `${i.quantity}x ${(i.product as any)?.name ?? i.productId}${i.notes ? `\n   > ${i.notes}` : ''}`),
      '--------------------------------',
    ];
    return lines.join('\n');
  }

  private async sendInternet(printer: Printer, ticketText: string) {
    const payload = Buffer.from(ticketText).toString('base64');
    try {
      await lastValueFrom(
        this.http.post(
          printer.endpointUrl,
          { encoding: 'base64', payload },
          {
            headers: { Authorization: `Bearer ${printer.token}`, 'Content-Type': 'application/json' },
            timeout: 6000,
          },
        ),
      );
      this.logger.log(`Internet print job sent to ${printer.name}`);
    } catch (err) {
      this.logger.error(`Failed to send to ${printer.name}: ${err.message}`);
    }
  }
}
