import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

enum TicketBlockType { header, items, totals, footer, image, qr, divider }

class TicketBlock {
  final String id;
  final TicketBlockType type;
  final Map<String, dynamic> data;
  bool isVisible;

  TicketBlock({
    required this.id,
    required this.type,
    required this.data,
    this.isVisible = true,
  });

  TicketBlock copyWith({Map<String, dynamic>? data, bool? isVisible}) {
    return TicketBlock(
      id: id,
      type: type,
      data: data ?? this.data,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class TicketConfigModel {
  final List<TicketBlock> blocks;

  TicketConfigModel({
    List<TicketBlock>? blocks,
  }) : blocks = blocks ?? _defaultBlocks();

  static List<TicketBlock> _defaultBlocks() => [
    TicketBlock(id: 'img', type: TicketBlockType.image, data: {'path': null, 'size': 60.0}),
    TicketBlock(id: 'hdr', type: TicketBlockType.header, data: {
      'name': 'COMANDIX RESTO',
      'address': 'Calle Falsa 123, Ciudad',
      'phone': '+54 11 1234-5678',
    }),
    TicketBlock(id: 'div1', type: TicketBlockType.divider, data: {}),
    TicketBlock(id: 'itm', type: TicketBlockType.items, data: {}),
    TicketBlock(id: 'div2', type: TicketBlockType.divider, data: {}),
    TicketBlock(id: 'tot', type: TicketBlockType.totals, data: {}),
    TicketBlock(id: 'qr', type: TicketBlockType.qr, data: {'content': 'https://comandix.com/pay', 'size': 80.0}, isVisible: false),
    TicketBlock(id: 'ftr', type: TicketBlockType.footer, data: {'message': '¡Gracias por su visita!'}),
  ];

  TicketConfigModel copyWith({List<TicketBlock>? blocks}) {
    return TicketConfigModel(blocks: blocks ?? this.blocks);
  }

  String generateRawTicket() {
    StringBuffer sb = StringBuffer();
    for (var block in blocks) {
      if (!block.isVisible) continue;
      switch (block.type) {
        case TicketBlockType.header:
          sb.writeln(block.data['name'].toString().toUpperCase());
          sb.writeln(block.data['address']);
          sb.writeln('Tel: ${block.data['phone']}');
          break;
        case TicketBlockType.divider:
          sb.writeln('--------------------------------');
          break;
        case TicketBlockType.items:
          sb.writeln('2x Hamburguesa Pro       12.500');
          sb.writeln('1x Coca Cola 500ml        2.100');
          sb.writeln('1x Papas Grandes          4.500');
          break;
        case TicketBlockType.totals:
          sb.writeln('TOTAL                    \$19.100');
          break;
        case TicketBlockType.footer:
          sb.writeln('\n${block.data['message']}');
          break;
        case TicketBlockType.image:
          sb.writeln('[LOGO]');
          break;
        case TicketBlockType.qr:
          sb.writeln('[QR CODE: ${block.data['content']}]');
          break;
      }
    }
    return sb.toString();
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
            _buildRippedEdge(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: config.blocks.where((b) => b.isVisible).map((block) {
                  return _buildBlock(block);
                }).toList(),
              ),
            ),
            _buildRippedEdge(isBottom: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(TicketBlock block) {
    switch (block.type) {
      case TicketBlockType.image:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: block.data['path'] != null
              ? Image.file(File(block.data['path']), height: block.data['size'])
              : Icon(Icons.image_rounded, size: block.data['size'], color: Colors.black12),
        );
      case TicketBlockType.header:
        return Column(
          children: [
            Text(
              block.data['name'].toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Courier'),
            ),
            Text(
              block.data['address'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 10, fontFamily: 'Courier'),
            ),
            Text(
              'Tel: ${block.data['phone']}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 10, fontFamily: 'Courier'),
            ),
            const SizedBox(height: 10),
          ],
        );
      case TicketBlockType.divider:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Colors.black12, thickness: 1, height: 1),
        );
      case TicketBlockType.items:
        return Column(
          children: [
            _buildItemRow('2x Hamburguesa Pro', '12.500'),
            _buildItemRow('1x Coca Cola 500ml', '2.100'),
            _buildItemRow('1x Papas Grandes', '4.500'),
          ],
        );
      case TicketBlockType.totals:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('TOTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Courier')),
              Text('\$19.100', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Courier')),
            ],
          ),
        );
      case TicketBlockType.qr:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(Icons.qr_code_2_rounded, size: block.data['size'], color: Colors.black87),
              const Text('ESCANEA PARA PAGAR', style: TextStyle(color: Colors.black54, fontSize: 8, fontFamily: 'Courier')),
            ],
          ),
        );
      case TicketBlockType.footer:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            block.data['message'],
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 11, fontStyle: FontStyle.italic, fontFamily: 'Courier'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
