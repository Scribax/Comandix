import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String productId;
  final int quantity;
  final double unitPriceSnapshot;
  final String productNameSnapshot;
  final String? notes;
  final DateTime? sentToKitchenAt;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPriceSnapshot,
    required this.productNameSnapshot,
    this.notes,
    this.sentToKitchenAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      quantity: json['quantity'] as int,
      unitPriceSnapshot: double.tryParse(json['unitPriceSnapshot']?.toString() ?? '0') ?? 0.0,
      productNameSnapshot: json['productNameSnapshot'] as String,
      notes: json['notes'] as String?,
      sentToKitchenAt: json['sentToKitchenAt'] != null ? DateTime.parse(json['sentToKitchenAt']) : null,
    );
  }
}
