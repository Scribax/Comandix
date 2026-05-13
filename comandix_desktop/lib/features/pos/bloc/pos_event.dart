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

class PosCategorySelected extends PosEvent {
  final String categoryId;
  PosCategorySelected(this.categoryId);
}

class PosProductTapped extends PosEvent {
  final String productId;
  final String tableId;
  PosProductTapped(this.productId, this.tableId);
}

class PosDraftItemRemoved extends PosEvent {
  final String tableId;
  final int index;
  PosDraftItemRemoved(this.tableId, this.index);
}

class PosOrderSentToKitchen extends PosEvent {
  final String orderId;
  final String tableId;
  PosOrderSentToKitchen(this.orderId, this.tableId);
}

class PosOrderClosed extends PosEvent {
  final String orderId;
  final String paymentMethod;
  PosOrderClosed(this.orderId, this.paymentMethod);
}

class PosViewChanged extends PosEvent {
  final int viewIndex;
  PosViewChanged(this.viewIndex);
}

class PosItemVoided extends PosEvent {
  final String orderId;
  final String itemId;
  PosItemVoided(this.orderId, this.itemId);
}

class PosSectorCreated extends PosEvent {
  final String name;
  PosSectorCreated(this.name);
}

class PosItemNoteUpdated extends PosEvent {
  final String tableId;
  final int index;
  final String note;
  PosItemNoteUpdated(this.tableId, this.index, this.note);
}

// Menu Management Events
class PosCategoryCreated extends PosEvent {
  final Map<String, dynamic> data;
  PosCategoryCreated(this.data);
}

class PosCategoryUpdated extends PosEvent {
  final String id;
  final Map<String, dynamic> data;
  PosCategoryUpdated(this.id, this.data);
}

class PosCategoryDeleted extends PosEvent {
  final String id;
  PosCategoryDeleted(this.id);
}

class PosProductCreated extends PosEvent {
  final Map<String, dynamic> data;
  PosProductCreated(this.data);
}

class PosProductUpdated extends PosEvent {
  final String id;
  final Map<String, dynamic> data;
  PosProductUpdated(this.id, this.data);
}

class PosProductDeleted extends PosEvent {
  final String id;
  PosProductDeleted(this.id);
}

// Production Sector Events
class PosProductionSectorCreated extends PosEvent {
  final Map<String, dynamic> data;
  PosProductionSectorCreated(this.data);
}

class PosProductionSectorUpdated extends PosEvent {
  final String id;
  final Map<String, dynamic> data;
  PosProductionSectorUpdated(this.id, this.data);
}

class PosProductionSectorDeleted extends PosEvent {
  final String id;
  PosProductionSectorDeleted(this.id);
}
