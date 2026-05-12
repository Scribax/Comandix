import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Order } from './entities/order.entity';
import { Table } from '../layout/tables/entities/table.entity';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/pos',
})
export class OrdersGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('joinRestaurant')
  handleJoin(
    @MessageBody() data: { restaurantId: string },
    @ConnectedSocket() client: Socket,
  ) {
    client.join(`restaurant:${data.restaurantId}`);
    client.emit('joined', { room: `restaurant:${data.restaurantId}` });
  }

  emitNewKitchenOrder(restaurantId: string, order: Order) {
    this.server
      .to(`restaurant:${restaurantId}`)
      .emit('kitchen:newOrder', order);
  }

  emitTableUpdate(restaurantId: string, table: Table) {
    this.server
      .to(`restaurant:${restaurantId}`)
      .emit('table:statusChanged', { tableId: table.id, status: table.status });
  }

  emitOrderUpdated(restaurantId: string, order: Order) {
    this.server
      .to(`restaurant:${restaurantId}`)
      .emit('order:updated', order);
  }
}
