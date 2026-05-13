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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.categories.length,
                          itemBuilder: (context, index) {
                            final cat = state.categories[index];
                            final isSelected = cat.id == state.selectedCategoryId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: InkWell(
                                onTap: () => context.read<PosBloc>().add(PosCategorySelected(cat.id)),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.5) : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 4,
                                        height: isSelected ? 20 : 0,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6),
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            if (isSelected)
                                              BoxShadow(
                                                color: const Color(0xFF3B82F6).withOpacity(0.8),
                                                blurRadius: 8,
                                              )
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: isSelected ? 12 : 0),
                                      Expanded(
                                        child: Text(
                                          cat.name.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white38,
                                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                            fontSize: 13,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
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
                      // Header with Glass Effect
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.5),
                          border: const Border(bottom: BorderSide(color: Color(0xFF334155))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('RESUMEN DE CUENTA', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                const SizedBox(height: 4),
                                Text(
                                  'Mesa ${table.name}',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: activeOrder == null ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: activeOrder == null ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFF59E0B).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    activeOrder == null ? 'NUEVA ORDEN' : 'ORDEN ACTIVA',
                                    style: TextStyle(
                                      color: activeOrder == null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
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
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          border: const Border(top: BorderSide(color: Color(0xFF334155), width: 2)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, -10))
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL A PAGAR', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                Text('\$${total.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
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
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      side: BorderSide(color: draftItems.isNotEmpty ? const Color(0xFF3B82F6) : Colors.white10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: Text('COCINA', style: TextStyle(color: draftItems.isNotEmpty ? const Color(0xFF3B82F6) : Colors.white10, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        if (activeOrder != null && draftItems.isEmpty)
                                          BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: (activeOrder != null && draftItems.isEmpty)
                                          ? () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => PaymentDialog(
                                                  order: activeOrder,
                                                  onConfirm: (method) {
                                                    context.read<PosBloc>().add(PosOrderClosed(activeOrder.id, method));
                                                    Navigator.pop(context); // Solo cerrar el diálogo
                                                  },
                                                ),
                                              );
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        disabledBackgroundColor: Colors.white.withOpacity(0.05),
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      child: Text('COBRAR CUENTA', style: TextStyle(color: (activeOrder != null && draftItems.isEmpty) ? Colors.white : Colors.white10, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                                    ),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<PosBloc>().add(PosProductTapped(product.id, table.id));
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon/Image Placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fastfood_outlined, color: Color(0xFF3B82F6), size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PRECIO', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
                          Text('\$${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.add, size: 20, color: Colors.white),
                      )
                    ],
                  )
                ],
              ),
            ),
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
      child: InkWell(
        onTap: (!isPersisted && index != null) 
          ? () => _showNoteDialog(context, item, index) 
          : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.notes!,
                          style: const TextStyle(color: Colors.amber, fontSize: 12, fontStyle: FontStyle.italic),
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
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                      onPressed: () => context.read<PosBloc>().add(PosDraftItemRemoved(table.id, index)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (isPersisted && !isVoided && orderId != null)
                    InkWell(
                      onTap: () {
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
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, dynamic item, int index) {
    final controller = TextEditingController(text: item.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Nota para ${item.productNameSnapshot}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ej: Sin cebolla, término medio...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PosBloc>().add(PosItemNoteUpdated(table.id, index, controller.text));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: const Text('GUARDAR NOTA'),
          ),
        ],
      ),
    );
  }
}
