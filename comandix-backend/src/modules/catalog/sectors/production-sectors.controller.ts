import { Controller, Get, Post, Body, Param, Put, Delete, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ProductionSectorsService } from './production-sectors.service';
import { TenantId } from '../../../shared/decorators/tenant-id.decorator';
import { RolesGuard } from '../../../core/auth/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';

@Controller('production-sectors')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class ProductionSectorsController {
  constructor(private readonly sectorsService: ProductionSectorsService) {}

  @Get()
  findAll(@TenantId() restaurantId: string) {
    return this.sectorsService.findAllByRestaurant(restaurantId);
  }

  @Post()
  @Roles('admin', 'manager')
  create(@TenantId() restaurantId: string, @Body() body: { name: string, icon: string }) {
    return this.sectorsService.create(restaurantId, body.name, body.icon);
  }

  @Put(':id')
  @Roles('admin', 'manager')
  update(@Param('id') id: string, @Body() body: { name: string, icon: string }) {
    return this.sectorsService.update(id, body.name, body.icon);
  }

  @Delete(':id')
  @Roles('admin')
  remove(@Param('id') id: string) {
    return this.sectorsService.delete(id);
  }
}
