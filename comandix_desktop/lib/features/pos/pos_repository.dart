import '../../core/network/api_client.dart';
import '../../shared/models/sector_model.dart';
import '../../shared/models/table_model.dart';
import '../../shared/models/category_model.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/order_model.dart';

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
}
