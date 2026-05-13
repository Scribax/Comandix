import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String? orderId;
  final String productId;
  final ProductModel? product;
  final int quantity;
  final double unitPriceSnapshot;
  final String productNameSnapshot;
  final String? notes;
  final DateTime? sentToKitchenAt;
  final bool isVoided;

  OrderItemModel({
    required this.id,
    this.orderId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.unitPriceSnapshot,
    required this.productNameSnapshot,
    this.notes,
    this.sentToKitchenAt,
    this.isVoided = false,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String?,
      productId: json['productId'] as String,
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      quantity: json['quantity'] as int,
      unitPriceSnapshot: double.tryParse(json['unitPriceSnapshot']?.toString() ?? '0') ?? 0.0,
      productNameSnapshot: json['productNameSnapshot'] as String,
      notes: json['notes'] as String?,
      sentToKitchenAt: json['sentToKitchenAt'] != null ? DateTime.parse(json['sentToKitchenAt']) : null,
      isVoided: json['isVoided'] as bool? ?? false,
    );
  }
}
