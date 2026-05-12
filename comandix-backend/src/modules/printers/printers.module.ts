import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { Printer } from './entities/printer.entity';
import { PrinterRoute } from './entities/printer-route.entity';
import { PrintersService } from './printers.service';

@Module({
  imports: [TypeOrmModule.forFeature([Printer, PrinterRoute]), HttpModule],
  providers: [PrintersService],
  exports: [PrintersService],
})
export class PrintersModule {}
