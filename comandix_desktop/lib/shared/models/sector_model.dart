class SectorModel {
  final String id;
  final String name;
  final bool isActive;

  SectorModel({required this.id, required this.name, required this.isActive});

  factory SectorModel.fromJson(Map<String, dynamic> json) {
    return SectorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
