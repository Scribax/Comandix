import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../pos/bloc/pos_bloc.dart';
import '../pos/bloc/pos_state.dart';
import '../pos/bloc/pos_event.dart';
import '../../../shared/models/order_model.dart';
import 'dart:ui';
import 'dart:async';

import '../../../shared/models/table_model.dart';
import 'widgets/payment_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

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
                      childAspectRatio: 1.15,
                    ),
                    itemCount: state.activeOrders.length,
                    itemBuilder: (context, index) {
                      final order = state.activeOrders[index];
                      final table = state.tables.firstWhere((t) => t.id == order.tableId);
                      
                      return TweenAnimationBuilder(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.95 + (0.05 * value),
                              child: child,
                            ),
                          );
                        },
                        child: _buildOrderCard(context, order, table),
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

  Widget _buildOrderCard(BuildContext context, OrderModel order, TableModel table) {
    final activeItems = order.items.where((item) => !item.isVoided).toList();
    final activeTotal = activeItems.fold(0.0, (sum, item) => sum + (item.unitPriceSnapshot * item.quantity));
    
    final statusColor = _getStatusColor(order.status);
    final now = DateTime.now();
    final elapsed = now.difference(order.createdAt);
    final minutes = elapsed.inMinutes;

    Color timeColor = Colors.white.withOpacity(0.4);
    if (minutes >= 20) timeColor = const Color(0xFFEF4444); // Red
    else if (minutes >= 10) timeColor = const Color(0xFFF59E0B); // Amber

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.read<PosBloc>().add(PosTableSelected(table.id));
        },
        child: ClipRRect(
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
                  // Header
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
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
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
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length > 3 ? 4 : order.items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          if (i == 3 && order.items.length > 3) {
                            return Text(
                              '+ ${order.items.length - 3} items más...',
                              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12, fontStyle: FontStyle.italic),
                            );
                          }
                          final item = order.items[i];
                          final bool isVoided = item.isVoided;
                          return Row(
                            children: [
                              Text(
                                '${item.quantity}x', 
                                style: TextStyle(
                                  color: isVoided ? Colors.red.withOpacity(0.3) : statusColor, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12,
                                  decoration: isVoided ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.productNameSnapshot, 
                                  style: TextStyle(
                                    color: isVoided ? Colors.white24 : Colors.white70, 
                                    fontSize: 13, 
                                    fontWeight: isVoided ? FontWeight.normal : FontWeight.w500,
                                    decoration: isVoided ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVoided)
                                const Icon(Icons.block, color: Colors.redAccent, size: 10),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: timeColor),
                            const SizedBox(width: 4),
                            Text(
                              '$minutes min',
                              style: TextStyle(color: timeColor, fontSize: 13, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '\$${activeTotal.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => PaymentDialog(
                                    order: order,
                                    onConfirm: (method) {
                                      context.read<PosBloc>().add(PosOrderClosed(order.id, method));
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'COBRAR',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
