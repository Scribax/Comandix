import '../../core/network/api_client.dart';
import '../../shared/models/sector_model.dart';
import '../../shared/models/table_model.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/order_model.dart';
import '../../shared/models/production_sector_model.dart';
import '../../shared/models/printer_model.dart';

class PosRepository {
  final ApiClient apiClient;

  PosRepository({required this.apiClient});

  Future<List<SectorModel>> getSectors() async {
    final response = await apiClient.dio.get('/sectors');
    return (response.data as List).map((json) => SectorModel.fromJson(json)).toList();
  }

  Future<SectorModel> createSector(String name) async {
    final response = await apiClient.dio.post('/sectors', data: {'name': name});
    return SectorModel.fromJson(response.data);
  }

  Future<List<TableModel>> getTables() async {
    final response = await apiClient.dio.get('/tables');
    return (response.data as List).map((json) => TableModel.fromJson(json)).toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.dio.get('/categories');
    return (response.data as List).map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<List<ProductModel>> getProducts() async {
    final response = await apiClient.dio.get('/products');
    return (response.data as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  Future<List<OrderModel>> getActiveOrders() async {
    final response = await apiClient.dio.get('/orders');
    return (response.data as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  Future<OrderModel> createOrder(String tableId, {String? terminalId, List<Map<String, dynamic>>? items}) async {
    final response = await apiClient.dio.post('/orders', data: {
      'tableId': tableId,
      'terminalId': terminalId,
      'items': items ?? [],
    });
    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> addItemsToOrder(String orderId, List<Map<String, dynamic>> items) async {
    final response = await apiClient.dio.post('/orders/$orderId/items', data: items);
    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    final response = await apiClient.dio.patch('/orders/$orderId/status', data: {
      'status': status,
    });
    return OrderModel.fromJson(response.data);
  }

  Future<void> closeOrder(String orderId, String paymentMethod) async {
    await apiClient.dio.post('/orders/$orderId/close', data: {
      'paymentMethod': paymentMethod,
    });
  }

  Future<void> deleteOrder(String orderId) async {
    await apiClient.dio.delete('/orders/$orderId');
  }

  Future<OrderModel> voidItem(String orderId, String itemId) async {
    final response = await apiClient.dio.post('/orders/$orderId/items/$itemId/void');
    return OrderModel.fromJson(response.data);
  }

  Future<void> updateTables(List<TableModel> tables) async {
    await apiClient.dio.put('/tables/bulk', data: tables.map((t) => t.toJson()).toList());
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await apiClient.dio.get('/orders/stats/dashboard');
    return response.data as Map<String, dynamic>;
  }

  // Categories
  Future<CategoryModel> createCategory(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/categories', data: data);
    return CategoryModel.fromJson(response.data);
  }

  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.put('/categories/$id', data: data);
    return CategoryModel.fromJson(response.data);
  }

  Future<void> deleteCategory(String id) async {
    await apiClient.dio.delete('/categories/$id');
  }

  // Products
  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/products', data: data);
    return ProductModel.fromJson(response.data);
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.put('/products/$id', data: data);
    return ProductModel.fromJson(response.data);
  }

  Future<void> deleteProduct(String id) async {
    await apiClient.dio.delete('/products/$id');
  }

  // Production Sectors
  Future<List<ProductionSectorModel>> getProductionSectors() async {
    final response = await apiClient.dio.get('/production-sectors');
    return (response.data as List).map((json) => ProductionSectorModel.fromJson(json)).toList();
  }

  Future<ProductionSectorModel> createProductionSector(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/production-sectors', data: data);
    return ProductionSectorModel.fromJson(response.data);
  }

  Future<ProductionSectorModel> updateProductionSector(String id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.put('/production-sectors/$id', data: data);
    return ProductionSectorModel.fromJson(response.data);
  }

  // Printers
  Future<List<PrinterModel>> getPrinters() async {
    final response = await apiClient.dio.get('/printers');
    return (response.data as List).map((json) => PrinterModel.fromJson(json)).toList();
  }

  Future<PrinterModel> createPrinter(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/printers', data: data);
    return PrinterModel.fromJson(response.data);
  }

  Future<PrinterModel> updatePrinter(String id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.put('/printers/$id', data: data);
    return PrinterModel.fromJson(response.data);
  }

  Future<void> deletePrinter(String id) async {
    await apiClient.dio.delete('/printers/$id');
  }

  Future<void> testPrinter(String id) async {
    await apiClient.dio.post('/printers/$id/test');
  }
}
