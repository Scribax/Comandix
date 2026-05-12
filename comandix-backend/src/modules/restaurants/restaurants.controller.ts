import { Body, Controller, Get, Param, Post, Put, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { RestaurantsService } from './restaurants.service';
import { Roles } from '../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../core/auth/roles.guard';

@Controller('restaurants')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class RestaurantsController {
  constructor(private readonly svc: RestaurantsService) {}

  @Get()
  @Roles('admin')
  findAll() { return this.svc.findAll(); }

  @Post()
  @Roles('admin')
  create(@Body() body: any) { return this.svc.create(body); }

  @Get(':id')
  findOne(@Param('id') id: string) { return this.svc.findOne(id); }

  @Put(':id')
  @Roles('admin', 'manager')
  update(@Param('id') id: string, @Body() body: any) { return this.svc.update(id, body); }
}
