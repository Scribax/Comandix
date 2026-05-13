import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/kds_bloc.dart';
import 'bloc/kds_event.dart';
import 'bloc/kds_state.dart';
import '../pos/bloc/pos_bloc.dart';
import '../pos/bloc/pos_event.dart';
import '../../../shared/models/order_model.dart';
import 'dart:async';

class KdsScreen extends StatefulWidget {
  const KdsScreen({super.key});

  @override
  State<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends State<KdsScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresh timer for "time elapsed" display
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF020617), // Deepest slate for kitchen
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.soup_kitchen_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      const Text(
                        'Monitor de Cocina (KDS)',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 32),
                    onPressed: () {
                      context.read<PosBloc>().add(PosViewChanged(0));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: BlocBuilder<KdsBloc, KdsState>(
                  builder: (context, state) {
                    if (state is KdsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is KdsError) {
                      return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
                    }
                    if (state is KdsLoaded) {
                      if (state.activeKitchenOrders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 80, color: Colors.white10),
                              const SizedBox(height: 16),
                              const Text('¡Todo al día! No hay comandas pendientes.', style: TextStyle(color: Colors.white24, fontSize: 18)),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: state.activeKitchenOrders.length,
                        itemBuilder: (context, index) {
                          final order = state.activeKitchenOrders[index];
                          return _buildKitchenTicket(context, order);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKitchenTicket(BuildContext context, OrderModel order) {
    final now = DateTime.now();
    final elapsed = now.difference(order.createdAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    // Ticket color based on wait time
    Color headerColor = const Color(0xFF1E293B);
    if (minutes >= 10) headerColor = const Color(0xFF991B1B); // Red for > 10 min
    else if (minutes >= 5) headerColor = const Color(0xFF92400E); // Orange for > 5 min

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Ticket Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mesa ${order.table?.name ?? '??'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
          ),
          
          // Ticket Body
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.productNameSnapshot,
                        style: TextStyle(
                          color: item.isVoided ? Colors.red.withOpacity(0.5) : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: item.isVoided ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<KdsBloc>().add(KdsOrderMarkedReady(order.id));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('LISTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
