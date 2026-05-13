import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../pos/bloc/pos_bloc.dart';
import '../pos/bloc/pos_state.dart';
import '../../../shared/models/order_model.dart';
import 'dart:ui';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return const Color(0xFF6366F1); // Indigo
      case 'sent_to_kitchen': return const Color(0xFFF59E0B); // Amber
      case 'preparing': return const Color(0xFF3B82F6); // Blue
      case 'ready': return const Color(0xFF10B981); // Emerald
      case 'served': return const Color(0xFF8B5CF6); // Violet
      default: return const Color(0xFF64748B); // Slate
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft': return 'ATENDIENDO';
      case 'sent_to_kitchen': return 'EN COLA';
      case 'preparing': return 'PREPARANDO';
      case 'ready': return 'LISTO';
      case 'served': return 'SERVIDO';
      default: return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Pedidos',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.white54, size: 18),
                      const SizedBox(width: 8),
                      const Text('Todos los estados', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: BlocBuilder<PosBloc, PosState>(
                builder: (context, state) {
                  if (state is! PosLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.activeOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 80, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay pedidos activos',
                            style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: state.activeOrders.length,
                    itemBuilder: (context, index) {
                      final order = state.activeOrders[index];
                      final table = state.tables.firstWhere((t) => t.id == order.tableId);
                      final statusColor = _getStatusColor(order.status);
                      
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.05),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with Top Accent
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.2))),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.table_restaurant, size: 18, color: statusColor),
                                          const SizedBox(width: 8),
                                          Text(
                                            table.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Text(
                                          _getStatusText(order.status),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Items List
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: ListView.separated(
                                      itemCount: order.items.length,
                                      separatorBuilder: (context, index) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
                                      ),
                                      itemBuilder: (context, i) {
                                        final item = order.items[i];
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${item.quantity}x', 
                                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                item.productNameSnapshot, 
                                                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            Text(
                                              '\$${item.unitPriceSnapshot.toStringAsFixed(0)}',
                                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Footer Total
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '15 min', // Placeholder for time elapsed
                                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '\$${order.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white, 
                                          fontWeight: FontWeight.w900, 
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
