class TableModel {
  final String id;
  final String name;
  final String status;
  final String shape;
  final String type; // 'table', 'wall', 'decoration', 'label'
  final String? icon; // For decorations
  final String? color; // Hex color
  final String? labelText; // For generic labels
  final double posX;
  final double posY;
  final double width;
  final double height;
  final double rotation;
  final int zIndex;
  final String sectorId;

  TableModel({
    required this.id,
    required this.name,
    required this.status,
    required this.shape,
    this.type = 'table',
    this.icon,
    this.color,
    this.labelText,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    required this.rotation,
    this.zIndex = 0,
    required this.sectorId,
  });

  TableModel copyWith({
    String? id,
    String? name,
    String? status,
    String? shape,
    String? type,
    String? icon,
    String? color,
    String? labelText,
    double? posX,
    double? posY,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    String? sectorId,
  }) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      shape: shape ?? this.shape,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      labelText: labelText ?? this.labelText,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      sectorId: sectorId ?? this.sectorId,
    );
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      name: json['name'] ?? '',
      status: json['status'] ?? 'free',
      shape: json['shape'] ?? 'square',
      type: json['type'] ?? 'table',
      icon: json['icon'],
      color: json['color'],
      labelText: json['labelText'],
      posX: (json['posX'] ?? 0).toDouble(),
      posY: (json['posY'] ?? 0).toDouble(),
      width: (json['width'] ?? 80).toDouble(),
      height: (json['height'] ?? 80).toDouble(),
      rotation: (json['rotation'] ?? 0).toDouble(),
      zIndex: json['zIndex'] ?? 0,
      sectorId: json['sectorId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'shape': shape,
      'type': type,
      'icon': icon,
      'color': color,
      'labelText': labelText,
      'posX': posX,
      'posY': posY,
      'width': width,
      'height': height,
      'rotation': rotation,
      'zIndex': zIndex,
      'sectorId': sectorId,
    };
  }
}
