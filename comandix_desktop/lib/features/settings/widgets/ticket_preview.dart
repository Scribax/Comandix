import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TicketConfigModel {
  final String businessName;
  final String address;
  final String phone;
  final String footerMessage;
  final bool showLogo;
  final bool showDate;
  final bool showTable;

  TicketConfigModel({
    this.businessName = 'COMANDIX RESTO',
    this.address = 'Calle Falsa 123, Ciudad',
    this.phone = '+54 11 1234-5678',
    this.footerMessage = '¡Gracias por su visita!',
    this.showLogo = true,
    this.showDate = true,
    this.showTable = true,
  });

  TicketConfigModel copyWith({
    String? businessName,
    String? address,
    String? phone,
    String? footerMessage,
    bool? showLogo,
    bool? showDate,
    bool? showTable,
  }) {
    return TicketConfigModel(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      footerMessage: footerMessage ?? this.footerMessage,
      showLogo: showLogo ?? this.showLogo,
      showDate: showDate ?? this.showDate,
      showTable: showTable ?? this.showTable,
    );
  }
}

class TicketPreview extends StatelessWidget {
  final TicketConfigModel config;

  const TicketPreview({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ripped paper effect top
            _buildRippedEdge(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  if (config.showLogo)
                    const Icon(Icons.restaurant_menu_rounded, size: 40, color: Colors.black87)
                        .animate().scale(duration: 400.ms),
                  
                  const SizedBox(height: 12),
                  Text(
                    config.businessName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontFamily: 'Courier',
                    ),
                  ),
                  Text(
                    config.address,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 10, fontFamily: 'Courier'),
                  ),
                  Text(
                    'Tel: ${config.phone}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 10, fontFamily: 'Courier'),
                  ),
                  
                  const SizedBox(height: 15),
                  const Divider(color: Colors.black12, thickness: 1, height: 1),
                  const SizedBox(height: 10),
                  
                  if (config.showTable)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('MESA: 12', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                        Text('PERSONAS: 4', style: TextStyle(color: Colors.black, fontFamily: 'Courier')),
                      ],
                    ),
                  
                  if (config.showDate)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'FECHA: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} 20:45',
                        style: const TextStyle(color: Colors.black87, fontSize: 9, fontFamily: 'Courier'),
                      ),
                    ),
                  
                  const SizedBox(height: 15),
                  _buildItemRow('2x Hamburguesa Pro', '12.500'),
                  _buildItemRow('1x Coca Cola 500ml', '2.100'),
                  _buildItemRow('1x Papas Grandes', '4.500'),
                  
                  const SizedBox(height: 15),
                  const Divider(color: Colors.black, thickness: 1, height: 1),
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('TOTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Courier')),
                      Text('$19.100', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Courier')),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  Text(
                    config.footerMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // Ripped paper effect bottom
            _buildRippedEdge(isBottom: true),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.black87, fontSize: 11, fontFamily: 'Courier'),
            ),
          ),
          Text(
            '\$$price',
            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }

  Widget _buildRippedEdge({bool isBottom = false}) {
    return SizedBox(
      height: 10,
      width: double.infinity,
      child: CustomPaint(
        painter: RippedEdgePainter(isBottom: isBottom),
      ),
    );
  }
}

class RippedEdgePainter extends CustomPainter {
  final bool isBottom;

  RippedEdgePainter({required this.isBottom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isBottom) {
      path.moveTo(0, 0);
      for (double i = 0; i <= size.width; i += 10) {
        path.lineTo(i + 5, 10);
        path.lineTo(i + 10, 0);
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.moveTo(0, size.height);
      for (double i = 0; i <= size.width; i += 10) {
        path.lineTo(i + 5, 0);
        path.lineTo(i + 10, size.height);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
