abstract class PosEvent {}

class PosDataLoaded extends PosEvent {}

class PosSectorSelected extends PosEvent {
  final String sectorId;
  PosSectorSelected(this.sectorId);
}

class PosTableSelected extends PosEvent {
  final String tableId;
  PosTableSelected(this.tableId);
}

class PosOrderItemsAdded extends PosEvent {
  final String tableId;
  final List<Map<String, dynamic>> items;
  PosOrderItemsAdded(this.tableId, this.items);
}

class PosOrderSentToKitchen extends PosEvent {
  final String orderId;
  PosOrderSentToKitchen(this.orderId);
}

class PosOrderClosed extends PosEvent {
  final String orderId;
  final String paymentMethod;
  PosOrderClosed(this.orderId, this.paymentMethod);
}
