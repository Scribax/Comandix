import { Body, Controller, Delete, Get, Param, Post, Put, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { TenantId } from '../../shared/decorators/tenant-id.decorator';
import { Roles } from '../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../core/auth/roles.guard';

@Controller('users')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class UsersController {
  constructor(private readonly svc: UsersService) {}

  @Get()
  @Roles('admin', 'manager')
  findAll(@TenantId() restaurantId: string) { return this.svc.findAll(restaurantId); }

  @Post()
  @Roles('admin', 'manager')
  create(@TenantId() restaurantId: string, @Body() body: any) {
    return this.svc.create(restaurantId, body);
  }

  @Put(':id')
  @Roles('admin', 'manager')
  update(@Param('id') id: string, @Body() body: any) { return this.svc.update(id, body); }

  @Delete(':id')
  @Roles('admin')
  remove(@Param('id') id: string) { return this.svc.remove(id); }
}
