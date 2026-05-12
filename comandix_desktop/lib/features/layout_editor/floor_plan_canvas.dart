import 'package:flutter/material.dart';
import 'table_widget.dart';

class FloorPlanCanvas extends StatelessWidget {
  final List<Map<String, dynamic>> tables;
  final bool isEditing;
  final Function(String id, Offset delta)? onTableDragged;
  final Function(String id)? onTableTapped;

  const FloorPlanCanvas({
    super.key,
    required this.tables,
    this.isEditing = false,
    this.onTableDragged,
    this.onTableTapped,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 4.0,
      child: SizedBox(
        width: 3000,
        height: 2000,
        child: Stack(
          children: [
            // Background Grid (Optional CustomPaint can go here)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E2C), // Dark theme background
              ),
            ),
            
            // Render Tables
            ...tables.map((table) => TableWidget(
              id: table['id'],
              name: table['name'],
              status: table['status'],
              shape: table['shape'],
              posX: table['pos_x'],
              posY: table['pos_y'],
              width: table['width'],
              height: table['height'],
              rotation: table['rotation'],
              isEditing: isEditing,
              onTap: () {
                if (onTableTapped != null) {
                  onTableTapped!(table['id']);
                }
              },
              onDrag: (delta) {
                if (onTableDragged != null) {
                  onTableDragged!(table['id'], delta);
                }
              },
            )),
          ],
        ),
      ),
    );
  }
}
