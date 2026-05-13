import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { BullModule } from '@nestjs/bull';
import { Printer } from './entities/printer.entity';
import { PrinterRoute } from './entities/printer-route.entity';
import { PrintJob } from './entities/print-job.entity';
import { PrintersService } from './printers.service';
import { PrinterProcessor } from './printer.processor';
import { PrintersController } from './printers.controller';

@Module({
  controllers: [PrintersController],
  imports: [
    TypeOrmModule.forFeature([Printer, PrinterRoute, PrintJob]),
    HttpModule,
    BullModule.registerQueue({
      name: 'printer_queue',
      defaultJobOptions: {
        attempts: 5,
        backoff: { type: 'exponential', delay: 2000 },
        removeOnComplete: true,
      },
    }),
  ],
  providers: [PrintersService, PrinterProcessor],
  exports: [PrintersService],
})
export class PrintersModule {}
