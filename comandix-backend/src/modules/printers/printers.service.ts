import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import { Printer } from './entities/printer.entity';
import { PrinterRoute } from './entities/printer-route.entity';
import { PrintJob } from './entities/print-job.entity';
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
    @InjectRepository(PrintJob)
    private readonly jobsRepo: Repository<PrintJob>,
    @InjectQueue('printer_queue') private readonly printerQueue: Queue,
  ) {}

  async findAll(restaurantId: string) {
    return this.printersRepo.find({ where: { restaurantId }, relations: ['routes'] });
  }

  async create(restaurantId: string, data: any) {
    const printer = this.printersRepo.create({ ...data, restaurantId });
    return this.printersRepo.save(printer);
  }

  async update(restaurantId: string, id: string, data: any) {
    await this.printersRepo.update({ id, restaurantId }, data);
    return this.printersRepo.findOne({ where: { id, restaurantId } });
  }

  async delete(restaurantId: string, id: string) {
    return this.printersRepo.delete({ id, restaurantId });
  }

  async testPrint(restaurantId: string, id: string) {
    const printer = await this.printersRepo.findOne({ where: { id, restaurantId } });
    if (!printer) return;

    const ticketText = [
      '--------------------------------',
      '       PRUEBA DE IMPRESION      ',
      '         COMANDIX POS           ',
      '--------------------------------',
      `IMPRESORA: ${printer.name}`,
      `TIPO     : ${printer.type}`,
      `FECHA    : ${new Date().toLocaleDateString()}`,
      `HORA     : ${new Date().toLocaleTimeString()}`,
      '--------------------------------',
      '    SISTEMA LISTO PARA OPERAR   ',
      '--------------------------------',
    ].join('\n');

    if (printer.type === 'INTERNET') {
      await this.printerQueue.add('print_internet', { printer, ticketText });
    } else {
      this.logger.log(`[LAN-TEST] Test print job for ${printer.name} queued.`);
    }
  }

  async routeAndPrint(restaurantId: string, order: Order) {
    // 1. Load active routes
    const routes = await this.routesRepo.find({
      where: { restaurantId },
      relations: ['printer'],
    });

    // 2. Load all printers for sector-based routing
    const allPrinters = await this.printersRepo.find({ where: { restaurantId, isActive: true } });

    // 3. Group items by printer
    const jobs = new Map<string, { printer: Printer; items: OrderItem[] }>();
    for (const item of order.items) {
      const product = item.product as any;
      const catId = product?.categoryId;
      const sectorId = product?.category?.productionSectorId;
      
      // A. Check specific category route first
      let printer = routes.find(r => r.categoryId === catId)?.printer;
      
      // B. Fallback to sector-based printer
      if (!printer && sectorId) {
        printer = allPrinters.find(p => p.productionSectorId === sectorId);
      }

      if (!printer) continue;
      if (!jobs.has(printer.id)) jobs.set(printer.id, { printer, items: [] });
      jobs.get(printer.id)!.items.push(item);
    }

    // 4. Dispatch jobs
    for (const { printer, items } of jobs.values()) {
      const ticket = this.buildTicket(order, items);
      
      const printJob = this.jobsRepo.create({
        restaurantId,
        printerId: printer.id,
        orderId: order.id,
        status: 'pending',
      });
      await this.jobsRepo.save(printJob);

      if (printer.type === 'INTERNET') {
        await this.printerQueue.add('print_internet', { printer, ticketText: ticket, jobId: printJob.id });
        this.logger.log(`Internet print job queued for ${printer.name}`);
      } else {
        // LAN: handled by the Desktop App locally
        this.logger.log(`[LAN] Print job for ${printer.name} queued for local dispatch.`);
      }
    }
  }

  async printVoidTicket(restaurantId: string, order: Order, item: OrderItem) {
    // 1. Load active routes
    const routes = await this.routesRepo.find({
      where: { restaurantId },
      relations: ['printer'],
    });

    // 2. Find printer for this item's category
    const catId = (item.product as any)?.categoryId;
    if (!catId) return;

    const route = routes.find((r) => r.categoryId === catId && r.printer?.isActive);
    if (!route || !route.printer) return;

    const printer = route.printer;

    // 3. Build VOID ticket
    const time = new Date().toTimeString().substring(0, 5);
    const ticketText = [
      '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
      '        !!! ANULACION !!!       ',
      '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
      `MESA  : ${(order.table as any)?.name ?? order.tableId}`,
      `MOZO  : ${(order.user as any)?.name ?? 'N/A'}`,
      `HORA  : ${time}`,
      '--------------------------------',
      `PRODUCTO:`,
      `${item.quantity}x ${item.productNameSnapshot}`,
      '--------------------------------',
      '   FAVOR DETENER PREPARACION    ',
      '--------------------------------',
    ].join('\n');

    // 4. Dispatch job
    const printJob = this.jobsRepo.create({
      restaurantId,
      printerId: printer.id,
      orderId: order.id,
      status: 'pending',
    });
    await this.jobsRepo.save(printJob);

    if (printer.type === 'INTERNET') {
      await this.printerQueue.add('print_internet', { printer, ticketText, jobId: printJob.id });
    } else {
      this.logger.log(`[LAN-VOID] Void job for ${printer.name} queued.`);
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
}
