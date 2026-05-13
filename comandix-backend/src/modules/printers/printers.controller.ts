import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { PrintersService } from './printers.service';
import { AuthGuard } from '@nestjs/passport';
import { TenantId } from '../../common/decorators/tenant-id.decorator';
import { RolesGuard } from '../../auth/guards/roles.guard';

@Controller('printers')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class PrintersController {
  constructor(private readonly printersService: PrintersService) {}

  @Get()
  async findAll(@TenantId() restaurantId: string) {
    return this.printersService.findAll(restaurantId);
  }

  @Post()
  async create(@TenantId() restaurantId: string, @Body() data: any) {
    return this.printersService.create(restaurantId, data);
  }

  @Put(':id')
  async update(
    @TenantId() restaurantId: string,
    @Param('id') id: string,
    @Body() data: any,
  ) {
    return this.printersService.update(restaurantId, id, data);
  }

  @Delete(':id')
  async remove(@TenantId() restaurantId: string, @Param('id') id: string) {
    return this.printersService.delete(restaurantId, id);
  }

  @Post(':id/test')
  async testPrint(@TenantId() restaurantId: string, @Param('id') id: string) {
    return this.printersService.testPrint(restaurantId, id);
  }
}
