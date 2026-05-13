class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? productionSectorId;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon = 'category',
    this.color = '#3B82F6',
    this.productionSectorId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Sin nombre').toString(),
      icon: (json['icon'] ?? 'category').toString(),
      color: (json['color'] ?? '#3B82F6').toString(),
      productionSectorId: json['productionSectorId']?.toString(),
    );
  }
}
