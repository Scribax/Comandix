import {
  Body, Controller, Get, Param, Post, Patch, Delete, UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { OrdersService, CreateOrderDto, CloseOrderDto, UpdateOrderStatusDto, AddItemDto } from './orders.service';
import { TenantId } from '../../shared/decorators/tenant-id.decorator';
import { Roles } from '../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../core/auth/roles.guard';
import { UserId } from '../../shared/decorators/user-id.decorator';

@Controller('orders')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get()
  @Roles('admin', 'manager', 'cashier', 'waiter')
  getActive(@TenantId() restaurantId: string) {
    return this.ordersService.getActiveOrders(restaurantId);
  }

  @Post()
  @Roles('admin', 'manager', 'cashier', 'waiter')
  create(
    @TenantId() restaurantId: string,
    @UserId() waiterId: string,
    @Body() dto: CreateOrderDto,
  ) {
    return this.ordersService.openTable(restaurantId, waiterId, dto);
  }

  @Get(':id')
  @Roles('admin', 'manager', 'cashier', 'waiter')
  getOne(@TenantId() restaurantId: string, @Param('id') id: string) {
    return this.ordersService.getOrderById(restaurantId, id);
  }

  @Patch(':id/status')
  @Roles('admin', 'manager', 'cashier', 'waiter')
  updateStatus(
    @TenantId() restaurantId: string,
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.ordersService.updateStatus(restaurantId, id, dto.status);
  }

  @Post(':id/items')
  @Roles('admin', 'manager', 'cashier', 'waiter')
  addItems(
    @TenantId() restaurantId: string,
    @Param('id') id: string,
    @Body() items: AddItemDto[],
  ) {
    return this.ordersService.addItemsToOrder(restaurantId, id, items);
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

  @Post(':id/items/:itemId/void')
  @Roles('admin', 'manager')
  voidItem(
    @TenantId() restaurantId: string,
    @Param('id') id: string,
    @Param('itemId') itemId: string,
  ) {
    return this.ordersService.voidItem(restaurantId, id, itemId);
  }

  @Delete(':id')
  @Roles('admin', 'manager')
  remove(@TenantId() restaurantId: string, @Param('id') id: string) {
    return this.ordersService.deleteOrder(restaurantId, id);
  }
}
