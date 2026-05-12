import { Body, Controller, Delete, Get, Param, Post, Put, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ProductsService } from './products.service';
import { TenantId } from '../../../shared/decorators/tenant-id.decorator';
import { RolesGuard } from '../../../core/auth/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';

@Controller('products')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class ProductsController {
  constructor(private readonly svc: ProductsService) {}

  @Get()
  findAll(@TenantId() restaurantId: string) { return this.svc.findAll(restaurantId); }

  @Post()
  @Roles('admin', 'manager')
  create(@TenantId() restaurantId: string, @Body() body: any) { return this.svc.create(restaurantId, body); }

  @Put(':id')
  @Roles('admin', 'manager')
  update(@Param('id') id: string, @Body() body: any) { return this.svc.update(id, body); }

  @Delete(':id')
  @Roles('admin')
  remove(@Param('id') id: string) { return this.svc.remove(id); }
}
