import {
  Body, Controller, Get, Param, Post, UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { OrdersService, CreateOrderDto, CloseOrderDto } from './orders.service';
import { TenantId } from '../../shared/decorators/tenant-id.decorator';
import { Roles } from '../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../core/auth/roles.guard';

@Controller('orders')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get()
  getOpen(@TenantId() restaurantId: string) {
    return this.ordersService.getOpenOrders(restaurantId);
  }

  @Post('open')
  @Roles('admin', 'manager', 'cashier', 'waiter')
  open(
    @TenantId() restaurantId: string,
    @Body() dto: CreateOrderDto & { userId: string },
  ) {
    return this.ordersService.openTable(restaurantId, dto.userId, dto);
  }

  @Get(':id')
  getOne(@TenantId() restaurantId: string, @Param('id') id: string) {
    return this.ordersService.getOrderById(restaurantId, id);
  }

  @Post(':id/send-to-kitchen')
  @Roles('admin', 'manager', 'cashier', 'waiter')
  sendToKitchen(@TenantId() restaurantId: string, @Param('id') id: string) {
    return this.ordersService.sendToKitchen(restaurantId, id);
  }

  @Post(':id/close')
  @Roles('admin', 'manager', 'cashier')
  close(
    @TenantId() restaurantId: string,
    @Param('id') id: string,
    @Body() dto: CloseOrderDto,
  ) {
    return this.ordersService.closeOrder(restaurantId, id, dto);
  }
}
