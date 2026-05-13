import 'dart:math';
import 'package:flutter/material.dart';
import '../../../shared/models/table_model.dart';

class TableCard extends StatefulWidget {
  final TableModel table;
  final VoidCallback onTap;

  const TableCard({super.key, required this.table, required this.onTap});

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.table.status == 'waiting_payment') {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.table.status) {
      case 'free': return const Color(0xFF10B981); // Emerald
      case 'occupied': return const Color(0xFFEF4444); // Red
      case 'waiting_payment': return const Color(0xFFF59E0B); // Amber
      default: return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (widget.table.status) {
      case 'free': return 'Libre';
      case 'occupied': return 'Ocupada';
      case 'waiting_payment': return 'Por pagar';
      default: return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pulse animation wraps the whole card
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (ctx, child) => Transform.scale(
        scale: _pulseAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Slate 800
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.table.status != 'free' 
                    ? _statusColor.withOpacity(0.5) 
                    : const Color(0xFF334155), // Slate 700
                width: 1.5,
              ),
              boxShadow: widget.table.status != 'free' ? [
                BoxShadow(
                  color: _statusColor.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                )
              ] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Top Accent Line
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 4,
                      color: _statusColor,
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Name & Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.table.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                _statusLabel,
                                style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Center Graphic (Table visualization)
                        Center(
                          child: Icon(
                            widget.table.shape == 'circle' ? Icons.circle : Icons.square_rounded,
                            size: 48,
                            color: _statusColor.withOpacity(0.8),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Footer: Time or Details
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            Text(
                              widget.table.status == 'free' ? '--:--' : '45 min',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            if (widget.table.status != 'free')
                              Icon(Icons.receipt_long, size: 16, color: Colors.white.withOpacity(0.7)),
                          ],
                        )
                      ],
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
}
