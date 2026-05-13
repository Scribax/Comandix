import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../pos/bloc/pos_bloc.dart';
import '../pos/bloc/pos_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state is! PosLoaded || state.dashboardStats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = state.dashboardStats!;
        final salesToday = stats['salesToday'] ?? 0.0;
        final salesYesterday = stats['salesYesterday'] ?? 0.0;
        final ordersCount = stats['ordersCount'] ?? 0;
        final occupation = stats['occupationPercent'] ?? 0.0;
        final salesByHour = (stats['salesByHour'] as List? ?? []);
        final topProducts = (stats['topProducts'] as List? ?? []);

        // Calculate growth percentage
        double growth = 0;
        if (salesYesterday > 0) {
          growth = ((salesToday - salesYesterday) / salesYesterday) * 100;
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CENTRO DE CONTROL',
                            style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Resumen Operativo',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Key Metrics Row
                  Row(
                    children: [
                      _buildMetricCard('VENTAS HOY', '\$${salesToday.toStringAsFixed(0)}', Icons.payments_rounded, const Color(0xFF10B981), growth),
                      const SizedBox(width: 24),
                      _buildMetricCard('PEDIDOS', ordersCount.toString(), Icons.receipt_long_rounded, const Color(0xFF3B82F6), 0),
                      const SizedBox(width: 24),
                      _buildMetricCard('OCUPACIÓN', '${occupation.toStringAsFixed(0)}%', Icons.chair_rounded, const Color(0xFFF59E0B), 0),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Charts Area
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMainChart(salesByHour)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTopProducts(topProducts)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Recent Activity
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Text('SISTEMA ONLINE', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, double growth) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, spreadRadius: -5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Icon(icon, color: color.withOpacity(0.5), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (growth != 0)
              Row(
                children: [
                  Icon(growth > 0 ? Icons.trending_up : Icons.trending_down, color: growth > 0 ? color : Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text('${growth > 0 ? '+' : ''}${growth.toStringAsFixed(1)}% vs ayer', style: TextStyle(color: growth > 0 ? color : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainChart(List salesByHour) {
    final maxVal = salesByHour.fold<double>(1.0, (max, s) => (s['total'] > max) ? s['total'].toDouble() : max);

    return Container(
      height: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VENTAS POR HORA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: salesByHour.map((s) {
                final double total = (s['total'] as num).toDouble();
                final double heightPercent = total / maxVal;
                final double height = 10 + (heightPercent * 180);
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.8),
                            const Color(0xFF3B82F6).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('${s['hour']}h', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List topProducts) {
    final maxCount = topProducts.isEmpty ? 1 : topProducts[0]['count'] as int;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOP PLATOS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          ...topProducts.map((p) => _buildProductRow(
            p['name'], 
            p['count'].toString(), 
            (p['count'] as int) / maxCount
          )),
        ],
      ),
    );
  }

  Widget _buildProductRow(String name, String count, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(count, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACTIVIDAD RECIENTE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          _buildActivityItem('Mesa 4 finalizada', 'Hace 2 min', Icons.check_circle, const Color(0xFF10B981)),
          _buildActivityItem('Nuevo pedido Mesa 1', 'Hace 5 min', Icons.add_shopping_cart, const Color(0xFF3B82F6)),
          _buildActivityItem('Anulación en Mesa 2', 'Hace 12 min', Icons.error_outline, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(time, style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}
