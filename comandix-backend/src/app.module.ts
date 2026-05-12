import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { BullModule } from '@nestjs/bull';

import { AuthModule } from './core/auth/auth.module';
import { RestaurantsModule } from './modules/restaurants/restaurants.module';
import { UsersModule } from './modules/users/users.module';
import { SectorsModule } from './modules/layout/sectors/sectors.module';
import { TablesModule } from './modules/layout/tables/tables.module';
import { CategoriesModule } from './modules/catalog/categories/categories.module';
import { ProductsModule } from './modules/catalog/products/products.module';
import { OrdersModule } from './modules/orders/orders.module';
import { PrintersModule } from './modules/printers/printers.module';
import { ReportsModule } from './modules/reports/reports.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST'),
        port: config.get<number>('DB_PORT'),
        username: config.get<string>('DB_USER'),
        password: config.get<string>('DB_PASSWORD'),
        database: config.get<string>('DB_NAME'),
        autoLoadEntities: true,
        synchronize: config.get<string>('NODE_ENV') !== 'production' ||
          config.get<string>('DB_SYNC') === 'true',
      }),
    }),
    BullModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (config: ConfigService) => {
        const url = new URL(config.get<string>('REDIS_URL') || 'redis://redis:6379');
        return {
          redis: {
            host: url.hostname,
            port: parseInt(url.port || '6379', 10),
          },
        };
      },
    }),
    HttpModule,
    AuthModule,
    RestaurantsModule,
    UsersModule,
    SectorsModule,
    TablesModule,
    CategoriesModule,
    ProductsModule,
    OrdersModule,
    PrintersModule,
    ReportsModule,
  ],
})
export class AppModule {}
