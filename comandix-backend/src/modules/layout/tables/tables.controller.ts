import { Body, Controller, Delete, Get, Param, Post, Put, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TablesService } from './tables.service';
import { TenantId } from '../../../shared/decorators/tenant-id.decorator';
import { RolesGuard } from '../../../core/auth/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';

@Controller('tables')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class TablesController {
  constructor(private readonly svc: TablesService) {}

  @Get()
  findAll(@TenantId() restaurantId: string) { return this.svc.findAll(restaurantId); }

  @Get(':id')
  findOne(@TenantId() restaurantId: string, @Param('id') id: string) { return this.svc.findOne(restaurantId, id); }

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
