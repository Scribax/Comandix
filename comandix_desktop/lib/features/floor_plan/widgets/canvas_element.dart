import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../shared/models/table_model.dart';
import '../../../core/theme/app_theme.dart';

class CanvasElement extends StatefulWidget {
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
  State<CanvasElement> createState() => _CanvasElementState();
}

class _CanvasElementState extends State<CanvasElement> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final element = widget.element;
    final isSelected = widget.isSelected;
    final isReadOnly = widget.isReadOnly;

    final isWall = element.type == 'wall';
    final isDecoration = element.type == 'decoration';
    final isLabel = element.type == 'label';
    
    final customColor = element.color != null ? Color(int.parse(element.color!.replaceFirst('#', '0xFF'))) : null;
    final statusColor = isWall ? Colors.white54 : (isDecoration || isLabel ? (customColor ?? Colors.white70) : _getStatusColor(element.status));

    return Positioned(
      left: element.posX,
      top: element.posY,
      child: Transform.rotate(
        angle: element.rotation * math.pi / 180,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            onPanStart: isReadOnly ? null : (_) => widget.onDragStart(),
            onPanUpdate: isReadOnly ? null : (details) {
              // We need to rotate the delta back to global coordinates
              // because the GestureDetector is inside a Transform.rotate
              final double radians = element.rotation * math.pi / 180;
              final double cosTheta = math.cos(radians);
              final double sinTheta = math.sin(radians);
              
              // Standard rotation matrix:
              // x' = x*cos - y*sin
              // y' = x*sin + y*cos
              final double rotatedX = details.delta.dx * cosTheta - details.delta.dy * sinTheta;
              final double rotatedY = details.delta.dx * sinTheta + details.delta.dy * cosTheta;
              
              widget.onDrag(Offset(rotatedX, rotatedY));
            },
            onPanEnd: isReadOnly ? null : (_) => widget.onDragEnd(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: element.width,
              height: element.height,
              decoration: BoxDecoration(
                color: isWall 
                    ? Colors.white.withOpacity(isSelected || _isHovered ? 0.4 : 0.15)
                    : isLabel || isDecoration
                        ? Colors.transparent
                        : (isSelected || _isHovered ? AppColors.accent.withOpacity(0.3) : AppColors.backgroundSecondary.withOpacity(0.8)),
                borderRadius: isWall 
                    ? BorderRadius.circular(4) 
                    : (element.shape == 'circle' ? BorderRadius.circular(element.width / 2) : BorderRadius.circular(12)),
                border: Border.all(
                  color: (isSelected || _isHovered)
                      ? (isWall || isLabel || isDecoration ? Colors.white : AppColors.accent) 
                      : (isWall ? Colors.white12 : (isLabel || isDecoration ? Colors.transparent : AppColors.glassBorder)),
                  width: (isSelected || _isHovered) ? 2 : 1,
                ),
                boxShadow: [
                  if (!isWall && !isLabel && !isDecoration)
                    BoxShadow(
                      color: statusColor.withOpacity(_isHovered ? 0.6 : 0.3),
                      blurRadius: (isSelected || _isHovered) ? 35 : 15,
                      spreadRadius: (isSelected || _isHovered) ? 8 : 2,
                    ),
                  if (isSelected || _isHovered)
                    BoxShadow(
                      color: (isWall || isLabel || isDecoration ? Colors.white : AppColors.accent).withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 2,
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
                            onEnd: () {},
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
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'wc': return Icons.wc;
      case 'male': return Icons.male;
      case 'female': return Icons.female;
      case 'kitchen': return Icons.soup_kitchen;
      case 'restaurant': return Icons.restaurant;
      case 'coffee': return Icons.coffee;
      case 'pizza': return Icons.local_pizza;
      case 'cake': return Icons.cake;
      case 'exit': return Icons.exit_to_app;
      case 'emergency': return Icons.emergency;
      case 'stairs': return Icons.stairs;
      case 'bar': return Icons.local_bar;
      case 'dj': return Icons.album;
      case 'pool': return Icons.pool;
      case 'entrance': return Icons.login;
      case 'danger': return Icons.warning;
      case 'fire': return Icons.fire_extinguisher;
      case 'wifi': return Icons.wifi;
      case 'medical': return Icons.medical_services;
      case 'parking': return Icons.local_parking;
      case 'no_smoking': return Icons.smoke_free;
      case 'delivery': return Icons.delivery_dining;
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
