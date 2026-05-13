import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/models/table_model.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import 'bloc/pos_bloc.dart';
import 'bloc/pos_event.dart';
import 'bloc/pos_state.dart';
import 'widgets/table_card.dart';
import '../orders/orders_screen.dart';
import '../kitchen/kds_screen.dart';
import '../delivery/delivery_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'order_taking_screen.dart';

class PosMainScreen extends StatefulWidget {
  const PosMainScreen({super.key});

  @override
  State<PosMainScreen> createState() => _PosMainScreenState();
}

class _PosMainScreenState extends State<PosMainScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PosBloc>().add(PosDataLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Tailwind Slate 900
      body: BlocBuilder<PosBloc, PosState>(
        builder: (context, state) {
          if (state is PosLoading || state is PosInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is PosError) {
            return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
          }

          if (state is PosLoaded) {
            final isKds = state.currentViewIndex == 2; 

            if (state.selectedTable != null) {
              return OrderTakingScreen(table: state.selectedTable!);
            }

            return Row(
              children: [
                if (!isKds) _buildSidebar(context, state.currentViewIndex, state.activeOrders.length),
                Expanded(
                  child: Stack(
                    children: [
                      // Soft background gradients for all screens
                      Positioned(
                        top: -100, right: -100,
                        child: _buildBlurryCircle(const Color(0xFF3B82F6), 400, 0.1),
                      ),
                      Positioned(
                        bottom: -100, left: 100,
                        child: _buildBlurryCircle(const Color(0xFF8B5CF6), 300, 0.1),
                      ),
                      
                      IndexedStack(
                        index: state.currentViewIndex,
                        children: [
                          _buildSalonView(context, state),
                          OrdersScreen(),
                          KdsScreen(),
                          DeliveryScreen(),
                          HistoryScreen(),
                          SettingsScreen(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSalonView(BuildContext context, PosLoaded state) {
    final activeTables = state.tables.where((t) => t.sectorId == state.selectedSectorId).toList();

    return Stack(
      children: [
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sector Tabs
                      if (state.sectors.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: state.sectors.map((sector) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: InkWell(
                                  onTap: () {
                                    context.read<PosBloc>().add(PosSectorSelected(sector.id));
                                  },
                                  borderRadius: BorderRadius.circular(100),
                                  child: _buildSectorTab(sector.name, state.selectedSectorId == sector.id),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                      
                      // Tables Grid
                      Expanded(
                        child: activeTables.isEmpty 
                          ? Center(child: Text('No hay mesas en este sector.', style: TextStyle(color: Colors.white54)))
                          : GridView.builder(
                              padding: const EdgeInsets.only(bottom: 32),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: activeTables.length,
                              itemBuilder: (context, index) {
                                final table = activeTables[index];
                                final activeOrderIndex = state.activeOrders.indexWhere((o) => o.tableId == table.id);
                                final activeOrder = activeOrderIndex >= 0 ? state.activeOrders[activeOrderIndex] : null;

                                return TableCard(
                                  table: table,
                                  activeOrder: activeOrder,
                                  onTap: () {
                                    context.read<PosBloc>().add(PosTableSelected(table.id));
                                  },
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buen turno, Admin 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Viernes, 12 de Mayo - 19:45',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
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
                const Icon(Icons.search, color: Colors.white54, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Buscar mesa o producto...',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(width: 48),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Ctrl+K', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectorTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.5) : const Color(0xFF334155),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white54,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, int currentIndex, int activeOrdersCount) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120), // Darker slate
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'COMANDIX',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          _buildSidebarItem(context, 0, Icons.grid_view_rounded, 'Salón', currentIndex == 0),
          _buildSidebarItem(context, 1, Icons.receipt_long_rounded, 'Pedidos', currentIndex == 1, badge: activeOrdersCount > 0 ? activeOrdersCount.toString() : null),
          _buildSidebarItem(context, 2, Icons.soup_kitchen_rounded, 'Cocina', currentIndex == 2),
          _buildSidebarItem(context, 3, Icons.delivery_dining, 'Delivery', currentIndex == 3),
          _buildSidebarItem(context, 4, Icons.history_rounded, 'Historial', currentIndex == 4),
          
          const Spacer(),
          
          const Divider(color: const Color(0xFF1E293B), height: 1),
          _buildSidebarItem(context, 5, Icons.settings_outlined, 'Configuración', currentIndex == 5),
          
          // User profile at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3B82F6).withOpacity(0.2),
                    child: const Text('A', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Admin User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Cajero', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20, color: Colors.white54),
                    onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
                    tooltip: 'Cerrar sesión',
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, int index, IconData icon, String title, bool isSelected, {String? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<PosBloc>().add(PosViewChanged(index));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: isSelected ? const Color(0xFF3B82F6) : Colors.white54),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurryCircle(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
