import 'package:flutter/material.dart';
import '../../../shared/models/table_model.dart';

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
                        table.status == 'free' ? 'Nueva Orden' : 'Orden Activa',
                        style: TextStyle(
                          color: table.status == 'free' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Categories Horizontal List (Mock)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Populares', true),
                _buildCategoryChip('Bebidas', false),
                _buildCategoryChip('Platos Principales', false),
                _buildCategoryChip('Postres', false),
              ],
            ),
          ),

          // Product Grid (Mock)
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
              itemCount: 4,
              itemBuilder: (context, index) {
                final products = [
                  {'name': 'Hamburguesa Classic', 'price': '\$12.00'},
                  {'name': 'Cerveza Artesanal', 'price': '\$4.50'},
                  {'name': 'Papas Fritas', 'price': '\$6.00'},
                  {'name': 'Gaseosa Cola', 'price': '\$2.50'},
                ];
                return _buildProductCard(products[index]['name']!, products[index]['price']!);
              },
            ),
          ),

          // Cart Items (Mock)
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0B1120),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Items en Comanda', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildCartItem('1x', 'Hamburguesa Classic', '\$12.00'),
                  _buildCartItem('2x', 'Cerveza Artesanal', '\$9.00'),
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
                  children: const [
                    Text('Total', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('\$21.00', style: TextStyle(color: Color(0xFF10B981), fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
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
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
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
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
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
    );
  }

  Widget _buildProductCard(String name, String price) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
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
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(price, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
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

  Widget _buildCartItem(String qty, String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(4)),
            child: Text(qty, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white))),
          Text(price, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
