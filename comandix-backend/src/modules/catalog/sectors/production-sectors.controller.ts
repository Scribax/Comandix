import { Controller, Get, Post, Body, Param, Put, Delete, UseGuards, Request } from '@nestjs/common';
import { ProductionSectorsService } from './production-sectors.service';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';

@Controller('production-sectors')
@UseGuards(JwtAuthGuard)
export class ProductionSectorsController {
  constructor(private readonly sectorsService: ProductionSectorsService) {}

  @Get()
  findAll(@Request() req) {
    return this.sectorsService.findAllByRestaurant(req.user.restaurantId);
  }

  @Post()
  create(@Request() req, @Body() body: { name: string, icon: string }) {
    return this.sectorsService.create(req.user.restaurantId, body.name, body.icon);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() body: { name: string, icon: string }) {
    return this.sectorsService.update(id, body.name, body.icon);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.sectorsService.delete(id);
  }
}
