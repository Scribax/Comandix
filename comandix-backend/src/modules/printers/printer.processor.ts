import { Process, Processor } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import type { Job } from 'bull';
import { HttpService } from '@nestjs/axios';
import { lastValueFrom } from 'rxjs';
import { Printer } from './entities/printer.entity';

export interface PrintJobData {
  printer: Printer;
  ticketText: string;
}

@Processor('printer_queue')
export class PrinterProcessor {
  private readonly logger = new Logger(PrinterProcessor.name);

  constructor(private readonly http: HttpService) {}

  @Process('print_internet')
  async handlePrintInternet(job: Job<PrintJobData>) {
    const { printer, ticketText } = job.data;
    const payload = Buffer.from(ticketText).toString('base64');

    this.logger.log(`Processing print job ${job.id} for printer ${printer.name}`);

    try {
      await lastValueFrom(
        this.http.post(
          printer.endpointUrl,
          { encoding: 'base64', payload },
          {
            headers: { Authorization: `Bearer ${printer.token}`, 'Content-Type': 'application/json' },
            timeout: 8000,
          },
        ),
      );
      this.logger.log(`Print job ${job.id} completed successfully.`);
    } catch (err) {
      this.logger.error(`Failed job ${job.id} for ${printer.name}: ${err.message}`);
      // Throw error to trigger BullMQ's automatic retry mechanism
      throw err;
    }
  }
}
