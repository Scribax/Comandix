import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/models/product_model.dart';
import '../orders/widgets/payment_dialog.dart';
import 'bloc/pos_bloc.dart';
import 'bloc/pos_event.dart';
import 'bloc/pos_state.dart';

class OrderTakingScreen extends StatelessWidget {
  final TableModel table;

  const OrderTakingScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Row(
          children: [
            // Left Column: Categories (20%)
            Container(
              width: 180,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(right: BorderSide(color: Color(0xFF334155))),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        // Go back to Salon
                        final state = context.read<PosBloc>().state;
                        if (state is PosLoaded) {
                          context.read<PosBloc>().add(PosSectorSelected(state.selectedSectorId!));
                        }
                      },
                      tooltip: 'Volver al Salón',
                    ),
                  ),
                  const Divider(color: Color(0xFF334155), height: 1),
                  Expanded(
                    child: BlocBuilder<PosBloc, PosState>(
                      builder: (context, state) {
                        if (state is! PosLoaded) return const SizedBox.shrink();
                        return ListView.builder(
                          itemCount: state.categories.length,
                          itemBuilder: (context, index) {
                            final cat = state.categories[index];
                            final isSelected = cat.id == state.selectedCategoryId;
                            return InkWell(
                              onTap: () => context.read<PosBloc>().add(PosCategorySelected(cat.id)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
                                  border: Border(
                                    left: BorderSide(
                                      color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                                      width: 4,
                                    ),
                                    bottom: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                ),
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white54,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 16,
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

            // Middle Column: Products Grid (50%)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Catálogo',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Colors.white54, size: 20),
                              SizedBox(width: 8),
                              Text('Buscar producto...', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<PosBloc, PosState>(
                      builder: (context, state) {
                        if (state is! PosLoaded) return const SizedBox.shrink();
                        
                        final filteredProducts = state.products.where((p) => p.categoryId == state.selectedCategoryId).toList();
                        
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(context, product);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Right Column: Ticket / Order Panel (30%)
            Container(
              width: 380,
              decoration: const BoxDecoration(
                color: Color(0xFF0B1120),
                border: Border(left: BorderSide(color: Color(0xFF334155))),
              ),
              child: BlocBuilder<PosBloc, PosState>(
                builder: (context, state) {
                  if (state is! PosLoaded) return const SizedBox.shrink();

                  final activeOrder = state.activeOrders.where((o) => o.tableId == table.id).firstOrNull;

                  final draftItems = state.draftItems[table.id] ?? [];
                  final persistedItems = activeOrder?.items ?? [];
                  
                  // Subtotal without voided items is already handled by backend, but we calculate locally for draft
                  final draftSubtotal = draftItems.fold<double>(0.0, (double sum, item) => sum + (item.unitPriceSnapshot * item.quantity));
                  final persistedSubtotal = persistedItems.where((i) => !i.isVoided).fold<double>(0.0, (double sum, item) => sum + (item.unitPriceSnapshot * item.quantity));
                  final total = draftSubtotal + persistedSubtotal;

                  return Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        color: const Color(0xFF1E293B),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mesa ${table.name}',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activeOrder == null ? 'Nueva Orden' : 'Orden Activa #${activeOrder.id.substring(0,6)}',
                                  style: TextStyle(
                                    color: activeOrder == null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Items List
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Persisted Items
                            if (persistedItems.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text('Enviados', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                              ),
                              ...persistedItems.map((item) => _buildTicketItem(context, item, isPersisted: true, orderId: activeOrder?.id)),
                            ],
                            
                            if (persistedItems.isNotEmpty && draftItems.isNotEmpty)
                              const Divider(color: Color(0xFF334155), height: 32),
                              
                            // Draft Items
                            if (draftItems.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text('Nuevos (Sin Enviar)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                              ),
                              ...draftItems.asMap().entries.map((entry) => _buildTicketItem(context, entry.value, isPersisted: false, index: entry.key)),
                            ],
                            
                            if (persistedItems.isEmpty && draftItems.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 100),
                                  child: Text('La comanda está vacía', style: TextStyle(color: Colors.white38)),
                                ),
                              )
                          ],
                        ),
                      ),

                      // Footer Actions
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          border: Border(top: BorderSide(color: Color(0xFF334155))),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('\$${total.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 28, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: (draftItems.isNotEmpty)
                                        ? () {
                                            context.read<PosBloc>().add(PosOrderSentToKitchen(
                                                  activeOrder?.id ?? '',
                                                  table.id,
                                                ));
                                          }
                                        : null,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Color(0xFF3B82F6)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Cocina', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: (activeOrder != null && draftItems.isEmpty)
                                        ? () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => PaymentDialog(
                                                order: activeOrder,
                                                onConfirm: (method) {
                                                  context.read<PosBloc>().add(PosOrderClosed(activeOrder.id, method));
                                                  Navigator.pop(context); // Cerrar diálogo
                                                  Navigator.pop(context); // Volver al Salón
                                                },
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Cobrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<PosBloc>().add(PosProductTapped(product.id, table.id));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.name,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.w900)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 20, color: Color(0xFF3B82F6)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketItem(BuildContext context, dynamic item, {required bool isPersisted, int? index, String? orderId}) {
    final bool isVoided = isPersisted && item.isVoided;
    final totalItemPrice = item.unitPriceSnapshot * item.quantity;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isVoided 
                ? Colors.red.withOpacity(0.2) 
                : (isPersisted ? const Color(0xFF059669) : const Color(0xFF334155)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${item.quantity}x', style: TextStyle(
              color: isVoided ? Colors.red : Colors.white, 
              fontWeight: FontWeight.bold
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productNameSnapshot,
                  style: TextStyle(
                    color: isVoided ? Colors.redAccent : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    decoration: isVoided ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isVoided)
                  const Text('ANULADO', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${totalItemPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isVoided ? Colors.red.withOpacity(0.5) : Colors.white,
                  decoration: isVoided ? TextDecoration.lineThrough : null,
                ),
              ),
              if (!isPersisted && index != null)
                InkWell(
                  onTap: () {
                    context.read<PosBloc>().add(PosDraftItemRemoved(table.id, index));
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Quitar', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ),
              if (isPersisted && !isVoided && orderId != null)
                InkWell(
                  onTap: () {
                    // Trigger void item
                    context.read<PosBloc>().add(PosItemVoided(orderId, item.id));
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text('Anular', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
