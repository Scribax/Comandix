import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../shared/models/table_model.dart';
import '../../../core/theme/app_theme.dart';

class CanvasElement extends StatelessWidget {
  final TableModel element;
  final bool isSelected;
  final bool isReadOnly;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final Function(Offset delta) onDrag;
  final VoidCallback onDragEnd;

  const CanvasElement({
    super.key,
    required this.element,
    required this.isSelected,
    required this.isReadOnly,
    required this.onTap,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isWall = element.type == 'wall';
    final isDecoration = element.type == 'decoration';
    final isLabel = element.type == 'label';
    
    final customColor = element.color != null ? Color(int.parse(element.color!.replaceFirst('#', '0xFF'))) : null;
    final statusColor = isWall ? Colors.white54 : (isDecoration || isLabel ? (customColor ?? Colors.white70) : _getStatusColor(element.status));

    return Positioned(
      left: element.posX,
      top: element.posY,
      child: GestureDetector(
        onTap: onTap,
        onPanStart: isReadOnly ? null : (_) => onDragStart(),
        onPanUpdate: isReadOnly ? null : (details) => onDrag(details.delta),
        onPanEnd: isReadOnly ? null : (_) => onDragEnd(),
        child: Transform.rotate(
          angle: element.rotation * math.pi / 180,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: element.width,
              height: element.height,
              decoration: BoxDecoration(
                color: isWall 
                    ? Colors.white.withOpacity(isSelected ? 0.3 : 0.15)
                    : isLabel || isDecoration
                        ? Colors.transparent
                        : (isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.backgroundSecondary.withOpacity(0.8)),
                borderRadius: isWall 
                    ? BorderRadius.circular(4) 
                    : (element.shape == 'circle' ? BorderRadius.circular(element.width / 2) : BorderRadius.circular(12)),
                border: Border.all(
                  color: isSelected 
                      ? (isWall || isLabel || isDecoration ? Colors.white : AppColors.accent) 
                      : (isWall ? Colors.white12 : (isLabel || isDecoration ? Colors.transparent : AppColors.glassBorder)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (!isWall && !isLabel && !isDecoration)
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: isSelected ? 25 : 15,
                      spreadRadius: isSelected ? 5 : 2,
                    ),
                  if (isSelected)
                    BoxShadow(
                      color: (isWall || isLabel || isDecoration ? Colors.white : AppColors.accent).withOpacity(0.4),
                      blurRadius: 30,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isLabel && !isDecoration)
                    ClipRRect(
                      borderRadius: isWall 
                          ? BorderRadius.circular(4)
                          : (element.shape == 'circle' ? BorderRadius.circular(element.width / 2) : BorderRadius.circular(12)),
                      child: Container(color: Colors.transparent),
                    ),
                  if (element.type == 'table')
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (element.status == 'ready')
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.2),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutSine,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Icon(
                                  Icons.notifications_active,
                                  color: AppColors.success,
                                  size: math.min(element.width, element.height) * 0.4,
                                ),
                              );
                            },
                            onEnd: () {}, // Handled by the continuous nature of some builders or we can use a proper controller
                          ),
                        Text(
                          element.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (element.status != 'free')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              element.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (isDecoration && element.icon != null)
                    Icon(
                      _getIconData(element.icon!),
                      color: customColor ?? Colors.white70,
                      size: math.min(element.width, element.height) * 0.8,
                    ),
                  if (isLabel)
                    Text(
                      element.labelText ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: customColor ?? Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  if (element.shape == 'long_bar' && element.type == 'table')
                    Positioned(
                      top: 4,
                      child: Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'wc': return Icons.wc;
      case 'kitchen': return Icons.soup_kitchen;
      case 'exit': return Icons.exit_to_app;
      case 'stairs': return Icons.stairs;
      case 'bar': return Icons.local_bar;
      case 'dj': return Icons.album;
      case 'pool': return Icons.pool;
      case 'entrance': return Icons.login;
      default: return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'occupied': return AppColors.error;
      case 'waiting_payment': return AppColors.warning;
      case 'ready': return AppColors.success;
      default: return AppColors.accent;
    }
  }
}
