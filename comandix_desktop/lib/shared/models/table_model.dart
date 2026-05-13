class TableModel {
  final String id;
  final String name;
  final String status;
  final String shape;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final double rotation;
  final String sectorId;

  const TableModel({
    required this.id,
    required this.name,
    required this.status,
    required this.shape,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    required this.rotation,
    required this.sectorId,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) => TableModel(
        id: json['id'],
        name: json['name'],
        status: json['status'] ?? 'free',
        shape: json['shape'] ?? 'square',
        posX: double.tryParse(json['posX']?.toString() ?? '100') ?? 100.0,
        posY: double.tryParse(json['posY']?.toString() ?? '100') ?? 100.0,
        width: double.tryParse(json['width']?.toString() ?? '80') ?? 80.0,
        height: double.tryParse(json['height']?.toString() ?? '80') ?? 80.0,
        rotation: double.tryParse(json['rotation']?.toString() ?? '0') ?? 0.0,
        sectorId: json['sectorId'] ?? '',
      );
}
