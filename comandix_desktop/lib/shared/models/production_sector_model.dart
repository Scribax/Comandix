class ProductionSectorModel {
  final String id;
  final String name;
  final String icon;

  ProductionSectorModel({
    required this.id,
    required this.name,
    this.icon = 'kitchen',
  });

  factory ProductionSectorModel.fromJson(Map<String, dynamic> json) {
    return ProductionSectorModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Sin nombre').toString(),
      icon: (json['icon'] ?? 'kitchen').toString(),
    );
  }
}
