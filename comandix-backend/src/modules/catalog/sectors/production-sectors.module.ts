import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProductionSector } from './entities/production-sector.entity';
import { ProductionSectorsService } from './production-sectors.service';
import { ProductionSectorsController } from './production-sectors.controller';

@Module({
  imports: [TypeOrmModule.forFeature([ProductionSector])],
  providers: [ProductionSectorsService],
  controllers: [ProductionSectorsController],
  exports: [ProductionSectorsService],
})
export class ProductionSectorsModule {}
