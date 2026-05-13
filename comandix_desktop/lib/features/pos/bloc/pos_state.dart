import '../../../shared/models/sector_model.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/order_item_model.dart';
import '../../../shared/models/production_sector_model.dart';
import '../../../shared/models/printer_model.dart';

abstract class PosState {}

class PosInitial extends PosState {}

class PosLoading extends PosState {}

class PosLoaded extends PosState {
  final List<SectorModel> sectors;
  final List<TableModel> tables;
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final List<ProductionSectorModel> productionSectors;
  final List<PrinterModel> printers;
  final List<OrderModel> activeOrders;
  final String? selectedSectorId;
  final String? selectedCategoryId;
  final TableModel? selectedTable;
  // tableId -> list of items not yet sent to kitchen
  final Map<String, List<OrderItemModel>> draftItems;
  final int currentViewIndex;
  final Map<String, dynamic>? dashboardStats;

  PosLoaded({
    required this.sectors,
    required this.tables,
    required this.categories,
    required this.products,
    required this.productionSectors,
    required this.printers,
    required this.activeOrders,
    this.selectedSectorId,
    this.selectedCategoryId,
    this.selectedTable,
    this.draftItems = const {},
    this.currentViewIndex = 0,
    this.dashboardStats,
  });

  PosLoaded copyWith({
    List<SectorModel>? sectors,
    List<TableModel>? tables,
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    List<ProductionSectorModel>? productionSectors,
    List<PrinterModel>? printers,
    List<OrderModel>? activeOrders,
    String? selectedSectorId,
    String? selectedCategoryId,
    TableModel? selectedTable,
    Map<String, List<OrderItemModel>>? draftItems,
    bool clearSelectedTable = false,
    int? currentViewIndex,
    Map<String, dynamic>? dashboardStats,
  }) {
    return PosLoaded(
      sectors: sectors ?? this.sectors,
      tables: tables ?? this.tables,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      productionSectors: productionSectors ?? this.productionSectors,
      printers: printers ?? this.printers,
      activeOrders: activeOrders ?? this.activeOrders,
      selectedSectorId: selectedSectorId ?? this.selectedSectorId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedTable: clearSelectedTable ? null : (selectedTable ?? this.selectedTable),
      draftItems: draftItems ?? this.draftItems,
      currentViewIndex: currentViewIndex ?? this.currentViewIndex,
      dashboardStats: dashboardStats ?? this.dashboardStats,
    );
  }
}

class PosError extends PosState {
  final String message;
  PosError(this.message);
}
