import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/order_item_model.dart';
import '../bloc/pos_bloc.dart';
import '../bloc/pos_event.dart';
import '../bloc/pos_state.dart';

class OrderPanel extends StatelessWidget {
  final TableModel table;
  final VoidCallback onClose;

  const OrderPanel({
    super.key,
    required this.table,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state is! PosLoaded) return const SizedBox.shrink();

        final activeOrder = state.activeOrders.cast<OrderModel?>().firstWhere(
              (o) => o?.tableId == table.id,
              orElse: () => null,
            );

        final draftItems = state.draftItems[table.id] ?? [];
        final persistedItems = activeOrder?.items ?? [];
        final allItems = [...persistedItems, ...draftItems];

        final subtotal = allItems.fold<double>(0, (sum, item) => sum + (item.unitPriceSnapshot * item.quantity));

        final filteredProducts = state.products.where((p) => p.categoryId == state.selectedCategoryId).toList();

        return Container(
          width: 400,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: const Border(
              left: BorderSide(color: Color(0xFF1E293B), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(-5, 0),
              )
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF334155), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: onClose,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comanda: ${table.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeOrder == null ? 'Nueva Orden' : 'Orden Activa',
                            style: TextStyle(
                              color: activeOrder == null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Categories Horizontal List
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final cat = state.categories[index];
                    return _buildCategoryChip(
                      context,
                      cat.name,
                      cat.id == state.selectedCategoryId,
                      cat.id,
                    );
                  },
                ),
              ),

              // Product Grid
              Expanded(
                flex: 3,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(context, product);
                  },
                ),
              ),

              // Cart Items
              Expanded(
                flex: 2,
                child: Container(
                  color: const Color(0xFF0B1120),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Items en Comanda', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...persistedItems.map((item) => _buildCartItem(
                            '${item.quantity}x',
                            item.productNameSnapshot,
                            '\$${(item.unitPriceSnapshot * item.quantity).toStringAsFixed(2)}',
                            isPersisted: true,
                          )),
                      ...draftItems.asMap().entries.map((entry) => _buildCartItem(
                            '${entry.value.quantity}x',
                            entry.value.productNameSnapshot,
                            '\$${(entry.value.unitPriceSnapshot * entry.value.quantity).toStringAsFixed(2)}',
                            isPersisted: false,
                            onRemove: () {
                              context.read<PosBloc>().add(PosDraftItemRemoved(table.id, entry.key));
                            },
                          )),
                    ],
                  ),
                ),
              ),

              // Total & Actions
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
                        Text('\$${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: (draftItems.isNotEmpty || activeOrder != null)
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
                            onPressed: (activeOrder != null)
                                ? () {
                                    context.read<PosBloc>().add(PosOrderClosed(activeOrder.id, 'cash'));
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cobrar Mesa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, bool isSelected, String id) {
    return GestureDetector(
      onTap: () => context.read<PosBloc>().add(PosCategorySelected(id)),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 16, color: Color(0xFF3B82F6)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(String qty, String name, String price, {required bool isPersisted, VoidCallback? onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPersisted ? const Color(0xFF059669) : const Color(0xFF334155),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(qty, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isPersisted ? Colors.white70 : Colors.white,
                fontStyle: isPersisted ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          Text(price, style: const TextStyle(color: Colors.white54)),
          if (!isPersisted && onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 16),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
