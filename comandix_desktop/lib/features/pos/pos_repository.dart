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

  Future<OrderModel> openTable(String tableId, {String? terminalId}) async {
    final response = await apiClient.dio.post('/orders/open', data: {
      'tableId': tableId,
      'terminalId': terminalId,
      'items': [],
    });
    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> addItemsToOrder(String orderId, List<Map<String, dynamic>> items) async {
    final response = await apiClient.dio.post('/orders/$orderId/items', data: {
      'items': items,
    });
    return OrderModel.fromJson(response.data);
  }

  Future<void> sendOrderToKitchen(String orderId) async {
    await apiClient.dio.post('/orders/$orderId/send-to-kitchen');
  }

  Future<void> closeOrder(String orderId, String paymentMethod) async {
    await apiClient.dio.post('/orders/$orderId/close', data: {
      'paymentMethod': paymentMethod,
    });
  }
}
