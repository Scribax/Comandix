class PrinterModel {
  final String id;
  final String name;
  final String type; // 'LAN' | 'INTERNET' | 'SYSTEM'
  final String? ipAddress;
  final int? port;
  final String? endpointUrl;
  final String? token;
  final String? productionSectorId;
  final bool isActive;

  PrinterModel({
    required this.id,
    required this.name,
    required this.type,
    this.ipAddress,
    this.port,
    this.endpointUrl,
    this.token,
    this.productionSectorId,
    this.isActive = true,
  });

  factory PrinterModel.fromJson(Map<String, dynamic> json) {
    return PrinterModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      ipAddress: json['ipAddress'],
      port: json['port'],
      endpointUrl: json['endpointUrl'],
      token: json['token'],
      productionSectorId: json['productionSectorId'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'ipAddress': ipAddress,
      'port': port,
      'endpointUrl': endpointUrl,
      'token': token,
      'productionSectorId': productionSectorId,
      'isActive': isActive,
    };
  }
}
