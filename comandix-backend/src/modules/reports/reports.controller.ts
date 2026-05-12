import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ReportsService } from './reports.service';
import { TenantId } from '../../shared/decorators/tenant-id.decorator';
import { RolesGuard } from '../../core/auth/roles.guard';
import { Roles } from '../../shared/decorators/roles.decorator';

@Controller('reports')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class ReportsController {
  constructor(private readonly svc: ReportsService) {}

  @Get('daily-sales')
  @Roles('admin', 'manager')
  getDailySales(
    @TenantId() restaurantId: string,
    @Query('date') date: string,
  ) {
    return this.svc.getDailySales(restaurantId, date);
  }
}
