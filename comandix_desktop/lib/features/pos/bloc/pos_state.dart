import '../../../shared/models/sector_model.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/order_model.dart';

abstract class PosState {}

class PosInitial extends PosState {}

class PosLoading extends PosState {}

class PosLoaded extends PosState {
  final List<SectorModel> sectors;
  final List<TableModel> tables;
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final List<OrderModel> activeOrders;
  final String? selectedSectorId;
  final TableModel? selectedTable;

  PosLoaded({
    required this.sectors,
    required this.tables,
    required this.categories,
    required this.products,
    required this.activeOrders,
    this.selectedSectorId,
    this.selectedTable,
  });

  PosLoaded copyWith({
    List<SectorModel>? sectors,
    List<TableModel>? tables,
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    List<OrderModel>? activeOrders,
    String? selectedSectorId,
    TableModel? selectedTable,
    bool clearSelectedTable = false,
  }) {
    return PosLoaded(
      sectors: sectors ?? this.sectors,
      tables: tables ?? this.tables,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      activeOrders: activeOrders ?? this.activeOrders,
      selectedSectorId: selectedSectorId ?? this.selectedSectorId,
      selectedTable: clearSelectedTable ? null : (selectedTable ?? this.selectedTable),
    );
  }
}

class PosError extends PosState {
  final String message;
  PosError(this.message);
}
