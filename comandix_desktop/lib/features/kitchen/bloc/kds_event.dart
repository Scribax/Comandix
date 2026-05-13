import '../../../shared/models/order_model.dart';

abstract class KdsEvent {}

class KdsStarted extends KdsEvent {}

class KdsOrderReceived extends KdsEvent {
  final OrderModel order;
  KdsOrderReceived(this.order);
}

class KdsOrderMarkedReady extends KdsEvent {
  final String orderId;
  KdsOrderMarkedReady(this.orderId);
}
