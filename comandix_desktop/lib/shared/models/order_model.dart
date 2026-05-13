import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String tableId;
  final String? waiterId;
  final String status;
  final String? terminalId;
  final double subtotal;
  final double tax;
  final double total;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.tableId,
    this.waiterId,
    required this.status,
    this.terminalId,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      tableId: json['tableId'] as String,
      waiterId: json['userId'] as String?, // Map userId from DB to waiterId in model
      status: json['status'] as String,
      terminalId: json['terminalId'] as String?,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
