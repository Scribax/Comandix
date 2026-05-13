class ProductModel {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String? imageBase64;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.imageBase64,
    required this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Sin nombre').toString(),
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      categoryId: (json['categoryId'] ?? '').toString(),
      imageBase64: json['imageBase64'] as String?,
      isActive: json['isActive'] is bool ? json['isActive'] : true,
    );
  }
}
