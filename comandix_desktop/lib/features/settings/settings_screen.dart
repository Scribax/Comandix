import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../pos/bloc/pos_bloc.dart';
import '../pos/bloc/pos_event.dart';
import '../pos/bloc/pos_state.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/production_sector_model.dart';
import '../../shared/models/printer_model.dart';
import '../../core/utils/printer_scanner.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // FIX: Listen to tab changes to update the "Add" button text
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state is! PosLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Decorative background glow
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(0.05),
                  ),
                  child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container()),
                ),
              ),
              
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(state),
                      const SizedBox(height: 40),
                      
                      // Custom Tab Bar (Glass style)
                      Row(
                        children: [
                          _buildCustomTabBar(),
                          const Spacer(),
                          _buildSearchBar(),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Tab Content with animation
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCategoriesList(state).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
                            _buildProductsList(state.products, state.categories).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
                            _buildProductionSectorsList(state.productionSectors).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
                            _buildPrintersList(state.printers).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(PosLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Text(
                'SISTEMA DE CONTROL',
                style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gestión de Menú',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
            ),
          ],
        ),
        _buildAddButton(state),
      ],
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: '  CATEGORÍAS  '),
          Tab(text: '  PRODUCTOS  '),
          Tab(text: '  SECTORES  '),
          Tab(text: '  IMPRESORAS  '),
        ],
      ),
    );
  }

  Widget _buildAddButton(PosLoaded state) {
    return ElevatedButton.icon(
      onPressed: () {
        if (_tabController.index == 0) {
          _showCategoryDialog(productionSectors: state.productionSectors);
        } else if (_tabController.index == 1) {
          _showProductDialog(categories: state.categories);
        } else if (_tabController.index == 2) {
          _showProductionSectorDialog();
        } else {
          _showPrinterDialog();
        }
      },
      icon: const Icon(Icons.add, size: 20),
      label: Text(
        _tabController.index == 0 
          ? 'Añadir Categoría' 
          : _tabController.index == 1 
            ? 'Añadir Producto' 
            : _tabController.index == 2
              ? 'Añadir Sector'
              : 'Añadir Impresora'
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Buscar...',
          hintStyle: TextStyle(color: Colors.white24),
          prefixIcon: Icon(Icons.search, color: Colors.white24),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(PosLoaded state) {
    final categories = state.categories;
    final filtered = categories.where((c) => c.name.toLowerCase().contains(_searchQuery)).toList();

    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.4,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final category = filtered[index];
        final color = _parseColor(category.color);
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withOpacity(0.2)),
                          ),
                          child: Icon(_getCategoryIcon(category.icon), color: color, size: 24),
                        ),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white38),
                          color: AppColors.backgroundSecondary,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const ListTile(leading: Icon(Icons.edit, color: Colors.white70), title: Text('Editar', style: TextStyle(color: Colors.white70))),
                              onTap: () => Future.delayed(Duration.zero, () => _showCategoryDialog(category: category, productionSectors: state.productionSectors)),
                            ),
                            PopupMenuItem(
                              child: const ListTile(leading: Icon(Icons.delete, color: AppColors.error), title: Text('Borrar', style: TextStyle(color: AppColors.error))),
                              onTap: () => Future.delayed(Duration.zero, () => _confirmDelete(category.id, true)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      category.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(color: color.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.accent;
    }
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'fastfood': return Icons.fastfood_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'local_bar': return Icons.local_bar_rounded;
      case 'coffee': return Icons.coffee_rounded;
      case 'icecream': return Icons.icecream_rounded;
      case 'cake': return Icons.cake_rounded;
      case 'pizza': return Icons.local_pizza_rounded;
      case 'beer': return Icons.sports_bar_rounded;
      case 'meat': return Icons.kebab_dining_rounded;
      default: return Icons.auto_awesome_mosaic_rounded;
    }
  }

  Widget _buildProductsList(List<ProductModel> products, List<CategoryModel> categories) {
    final filtered = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          child: DataTable(
            horizontalMargin: 32,
            columnSpacing: 40,
            headingRowHeight: 70,
            dataRowHeight: 80,
            headingRowColor: MaterialStateProperty.all(Colors.white.withOpacity(0.03)),
            columns: const [
              DataColumn(label: Text('PRODUCTO', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
              DataColumn(label: Text('CATEGORÍA', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
              DataColumn(label: Text('PRECIO', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
              DataColumn(label: Text('STOCK', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
              DataColumn(label: Text('ACCIONES', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
            ],
            rows: filtered.map((product) {
              final cat = categories.firstWhere((c) => c.id == product.categoryId, orElse: () => CategoryModel(id: '', name: 'N/A'));
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fastfood_rounded, color: Colors.white24, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(cat.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ),
                  DataCell(Text('\$${product.price}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 16))),
                  DataCell(
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: product.isActive,
                        activeColor: AppColors.success,
                        activeTrackColor: AppColors.success.withOpacity(0.2),
                        inactiveThumbColor: Colors.white24,
                        inactiveTrackColor: Colors.white10,
                        onChanged: (val) {
                          context.read<PosBloc>().add(PosProductUpdated(product.id, {'isActive': val}));
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        _buildActionIcon(Icons.edit_rounded, Colors.white38, () => _showProductDialog(product: product, categories: categories)),
                        const SizedBox(width: 8),
                        _buildActionIcon(Icons.delete_outline_rounded, AppColors.error.withOpacity(0.7), () => _confirmDelete(product.id, false)),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showCategoryDialog({CategoryModel? category, required List<ProductionSectorModel> productionSectors}) {
    final nameController = TextEditingController(text: category?.name);
    String selectedIcon = category?.icon ?? 'category';
    String selectedColor = category?.color ?? '#3B82F6';
    String? selectedSectorId = category?.productionSectorId;

    final icons = ['category', 'fastfood', 'restaurant', 'local_bar', 'coffee', 'icecream', 'cake', 'pizza', 'beer', 'meat'];
    final colors = ['#3B82F6', '#EF4444', '#10B981', '#F59E0B', '#9B59B6', '#E67E22'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
          title: Text(category == null ? 'Nueva Categoría' : 'Editar Categoría', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Nombre de la categoría', labelStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10))),
                  ),
                  const SizedBox(height: 32),
                  const Text('ICONO RELEVANTE', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: icons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedIcon = icon),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getCategoryIcon(icon), color: isSelected ? Colors.black : Colors.white54, size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text('COLOR DE IDENTIDAD', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: colors.map((colorStr) {
                      final isSelected = selectedColor == colorStr;
                      final color = Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
                      return InkWell(
                        onTap: () => setDialogState(() => selectedColor = colorStr),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text('SECTOR DE PRODUCCIÓN', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSectorId,
                        dropdownColor: AppColors.backgroundSecondary,
                        hint: const Text('Seleccionar Sector', style: TextStyle(color: Colors.white24, fontSize: 14)),
                        isExpanded: true,
                        items: productionSectors.map((sector) => DropdownMenuItem(value: sector.id, child: Text(sector.name, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (val) => setDialogState(() => selectedSectorId = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      final data = {'name': nameController.text, 'icon': selectedIcon, 'color': selectedColor, 'productionSectorId': selectedSectorId};
                      if (category == null) {
                        context.read<PosBloc>().add(PosCategoryCreated(data));
                      } else {
                        context.read<PosBloc>().add(PosCategoryUpdated(category.id, data));
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog({ProductModel? product, List<CategoryModel>? categories}) {
    final nameController = TextEditingController(text: product?.name);
    final priceController = TextEditingController(text: product?.price.toString());
    String selectedCatId = product?.categoryId ?? (categories != null && categories.isNotEmpty ? categories.first.id : '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(product == null ? 'Añadir Producto' : 'Editar Producto', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white54))),
              const SizedBox(height: 16),
              TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Precio', labelStyle: TextStyle(color: Colors.white54))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCatId,
                dropdownColor: AppColors.backgroundSecondary,
                decoration: const InputDecoration(labelText: 'Categoría', labelStyle: TextStyle(color: Colors.white54)),
                items: categories?.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setDialogState(() => selectedCatId = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () {
                final data = {'name': nameController.text, 'price': double.parse(priceController.text), 'categoryId': selectedCatId, 'isActive': product?.isActive ?? true};
                if (product == null) {
                  context.read<PosBloc>().add(PosProductCreated(data));
                } else {
                  context.read<PosBloc>().add(PosProductUpdated(product.id, data));
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('GUARDAR', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionSectorsList(List<ProductionSectorModel> sectors) {
    if (sectors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.kitchen_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 24),
            const Text('No hay sectores de producción creados', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: DataTable(
          headingRowHeight: 60,
          horizontalMargin: 24,
          columns: const [
            DataColumn(label: Text('NOMBRE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
            DataColumn(label: Text('ACCIONES', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
          ],
          rows: sectors.map((sector) {
            return DataRow(
              cells: [
                DataCell(Text(sector.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                DataCell(
                  Row(
                    children: [
                      _buildActionIcon(Icons.edit_rounded, Colors.white38, () => _showProductionSectorDialog(sector: sector)),
                      const SizedBox(width: 8),
                      _buildActionIcon(Icons.delete_outline_rounded, AppColors.error.withOpacity(0.7), () => _confirmDelete(sector.id, false, isProductionSector: true)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showProductionSectorDialog({ProductionSectorModel? sector}) {
    final nameController = TextEditingController(text: sector?.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(sector == null ? 'Nuevo Sector de Producción' : 'Editar Sector', style: const TextStyle(color: Colors.white)),
        content: TextField(controller: nameController, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white54))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final data = {'name': nameController.text, 'icon': 'kitchen'};
              if (sector == null) {
                context.read<PosBloc>().add(PosProductionSectorCreated(data));
              } else {
                context.read<PosBloc>().add(PosProductionSectorUpdated(sector.id, data));
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('GUARDAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintersList(List<PrinterModel> printers) {
    if (printers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 24),
            const Text('No hay impresoras configuradas', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.6,
      ),
      itemCount: printers.length,
      itemBuilder: (context, index) {
        final printer = printers[index];
        final bool isOnline = printer.isActive;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.02),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (printer.type == 'LAN' ? const Color(0xFF3B82F6) : const Color(0xFF9B59B6)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        printer.type == 'LAN' ? Icons.lan_rounded : Icons.cloud_done_rounded,
                        color: printer.type == 'LAN' ? const Color(0xFF3B82F6) : const Color(0xFF9B59B6),
                      ),
                    ),
                    Row(
                      children: [
                        _buildActionIcon(Icons.play_arrow_rounded, const Color(0xFF10B981), () {
                          context.read<PosBloc>().add(PosPrinterTestRequested(printer.id));
                        }),
                        const SizedBox(width: 8),
                        _buildActionIcon(Icons.edit_rounded, Colors.white38, () => _showPrinterDialog(printer: printer)),
                        const SizedBox(width: 8),
                        _buildActionIcon(Icons.delete_outline_rounded, AppColors.error, () => _confirmDelete(printer.id, false, isPrinter: true)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(printer.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      printer.type == 'LAN' ? (printer.ipAddress ?? 'Sin IP') : 'Cloud Interface',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? const Color(0xFF10B981) : Colors.white10,
                        boxShadow: [
                          if (isOnline) BoxShadow(color: const Color(0xFF10B981).withOpacity(0.5), blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: isOnline ? const Color(0xFF10B981) : Colors.white10,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrinterDialog({PrinterModel? printer}) {
    final state = context.read<PosBloc>().state as PosLoaded;
    final nameController = TextEditingController(text: printer?.name);
    final ipController = TextEditingController(text: printer?.ipAddress);
    final portController = TextEditingController(text: printer?.port?.toString() ?? '9100');
    final endpointController = TextEditingController(text: printer?.endpointUrl);
    final tokenController = TextEditingController(text: printer?.token);
    String selectedType = printer?.type ?? 'LAN';
    String? selectedSectorId = printer?.productionSectorId;
    List<DiscoveredPrinter> discoveredPrinters = [];
    bool isScanning = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 500,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.98),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Configuración de Impresora', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white38)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isScanning || discoveredPrinters.isNotEmpty || (!isScanning && discoveredPrinters.isEmpty)) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('DISPOSITIVOS CERCANOS', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: isScanning
                          ? Column(
                              children: [
                                const Icon(Icons.radar_rounded, color: AppColors.accent, size: 48)
                                    .animate(onPlay: (controller) => controller.repeat())
                                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds, curve: Curves.easeInOut)
                                    .rotate(begin: 0, end: 1, duration: 2.seconds),
                                const SizedBox(height: 16),
                                const Text('Buscando dispositivos...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                const Text('Escaneando Red y Windows', style: TextStyle(color: Colors.white24, fontSize: 11)),
                              ],
                            )
                          : discoveredPrinters.isEmpty
                              ? Column(
                                  children: [
                                    const Icon(Icons.search_rounded, color: Colors.white10, size: 48),
                                    const SizedBox(height: 16),
                                    const Text('Lista vacía', style: TextStyle(color: Colors.white24, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    const Text('Toca "BUSCAR" arriba', style: TextStyle(color: Colors.white12, fontSize: 11)),
                                  ],
                                )
                              : SizedBox(
                                  height: 110,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: discoveredPrinters.length,
                                    itemBuilder: (context, idx) {
                                      final p = discoveredPrinters[idx];
                                      final isSelected = nameController.text == p.name;
                                      return GestureDetector(
                                        onTap: () {
                                          setDialogState(() {
                                            nameController.text = p.name;
                                            selectedType = p.type;
                                            if (p.type == 'LAN') ipController.text = p.ip!;
                                          });
                                        },
                                        child: Container(
                                          width: 140,
                                          margin: const EdgeInsets.only(right: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: isSelected ? AppColors.accent.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(p.type == 'SYSTEM' ? Icons.desktop_windows_rounded : Icons.lan_rounded, 
                                                   color: isSelected ? AppColors.accent : Colors.white38, size: 24),
                                              const SizedBox(height: 8),
                                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, 
                                                   style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                              Text(p.type == 'SYSTEM' ? 'Windows' : p.ip!, style: const TextStyle(color: Colors.white24, fontSize: 9)),
                                            ],
                                          ),
                                        ).animate().scale(delay: (idx * 50).ms),
                                      );
                                    },
                                  ),
                                ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('CONFIGURACIÓN MANUAL', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      hintText: 'Nombre (ej: Cocina Principal)',
                      hintStyle: const TextStyle(color: Colors.white24, fontWeight: FontWeight.normal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.label_important_rounded, color: AppColors.accent, size: 20),
                    ),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSectorId,
                        hint: const Text('Vincular a Sector', style: TextStyle(color: Colors.white24, fontSize: 14)),
                        dropdownColor: const Color(0xFF1E293B),
                        isExpanded: true,
                        items: state.productionSectors.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: (val) => setDialogState(() => selectedSectorId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('CONFIGURACIÓN', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      TextButton(
                        onPressed: () => setDialogState(() => showAdvanced = !showAdvanced),
                        child: Text(showAdvanced ? 'SIMPLIFICAR' : 'AVANZADO', style: const TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (showAdvanced) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTypeToggle('LAN', 'Red Local', Icons.lan_rounded, selectedType, (val) => setDialogState(() => selectedType = val)),
                        const SizedBox(width: 8),
                        _buildTypeToggle('SYSTEM', 'Windows', Icons.desktop_windows_rounded, selectedType, (val) => setDialogState(() => selectedType = val)),
                        const SizedBox(width: 8),
                        _buildTypeToggle('INTERNET', 'Cloud', Icons.cloud_done_rounded, selectedType, (val) => setDialogState(() => selectedType = val)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (selectedType == 'LAN') ...[
                      TextField(
                        controller: ipController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Dirección IP', hintText: '192.168.1.100', labelStyle: TextStyle(color: Colors.white38)),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(selectedType == 'SYSTEM' ? Icons.desktop_windows_rounded : Icons.lan_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedType == 'SYSTEM' ? 'Modo Windows (USB/Driver)' : 'Modo Red (${ipController.text})',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (nameController.text.isEmpty || 
                                 (selectedType == 'LAN' && ipController.text.isEmpty) ||
                                 (selectedType == 'INTERNET' && (endpointController.text.isEmpty || tokenController.text.isEmpty)))
                        ? null
                        : () {
                          final data = {
                            'name': nameController.text,
                            'type': selectedType,
                            'ipAddress': selectedType == 'LAN' ? ipController.text : null,
                            'port': selectedType == 'LAN' ? int.tryParse(portController.text) ?? 9100 : null,
                            'endpointUrl': selectedType == 'INTERNET' ? endpointController.text : null,
                            'token': selectedType == 'INTERNET' ? tokenController.text : null,
                            'productionSectorId': selectedSectorId,
                            'isActive': true,
                          };
                          
                          if (printer == null) {
                            context.read<PosBloc>().add(PosPrinterCreated(data));
                          } else {
                            context.read<PosBloc>().add(PosPrinterUpdated(printer.id, data));
                          }
                          Navigator.pop(context);
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.backgroundSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: Text(printer == null ? 'GUARDAR IMPRESORA' : 'ACTUALIZAR CAMBIOS', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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

  Widget _buildTypeToggle(String value, String label, IconData icon, String selected, Function(String) onSelected) {
    bool isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.black : Colors.white38, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id, bool isCategory, {bool isProductionSector = false, bool isPrinter = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: const Text('¿Estás seguro?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              if (isCategory) {
                context.read<PosBloc>().add(PosCategoryDeleted(id));
              } else if (isProductionSector) {
                context.read<PosBloc>().add(PosProductionSectorDeleted(id));
              } else if (isPrinter) {
                context.read<PosBloc>().add(PosPrinterDeleted(id));
              } else {
                context.read<PosBloc>().add(PosProductDeleted(id));
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('BORRAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
