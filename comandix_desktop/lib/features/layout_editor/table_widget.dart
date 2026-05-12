import 'dart:math';
import 'package:flutter/material.dart';

class TableWidget extends StatelessWidget {
  final String id;
  final String name;
  final String status;
  final String shape;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final double rotation;
  final bool isEditing;
  final VoidCallback onTap;
  final Function(Offset delta)? onDrag;

  const TableWidget({
    super.key,
    required this.id,
    required this.name,
    required this.status,
    required this.shape,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    required this.rotation,
    required this.isEditing,
    required this.onTap,
    this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: isEditing && onDrag != null 
          ? (details) => onDrag!(details.delta) 
          : null,
        child: Transform.rotate(
          angle: rotation * (pi / 180),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _colorForStatus(status),
              borderRadius: shape == 'circle'
                  ? BorderRadius.circular(max(width, height) / 2)
                  : BorderRadius.circular(8),
              border: Border.all(color: Colors.white54, width: 2),
              boxShadow: [
                if (isEditing)
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Center(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'free':
        return const Color(0xFF2ECC71); // Green
      case 'occupied':
        return const Color(0xFFE74C3C); // Red
      case 'waiting_payment':
        return const Color(0xFFF39C12); // Amber
      default:
        return Colors.grey;
    }
  }
}
