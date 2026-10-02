import '../models/address.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrderPage {
  final List<Order> items;
  final int totalCount;
  final int page;
  final int pageSize;
  const OrderPage({required this.items, required this.totalCount, required this.page, required this.pageSize});
}

class OrdersRepository {
  OrdersRepository._();

  static Future<Order> createOrder({
    required String addressId,
    required DeliveryCountry country,
    required PaymentMethod paymentMethod,
  }) async {
    final data = await ApiClient.instance.post('/orders', body: {
      'addressId': addressId,
      'deliveryCountry': country.index,
      'paymentMethod': paymentMethod.index,
    }) as Map<String, dynamic>;
    return Order.fromJson(data);
  }

  static Future<OrderPage> getMyOrders({int page = 1, int pageSize = 20}) async {
    final data = await ApiClient.instance.get('/orders', query: {'page': page, 'pageSize': pageSize}) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    return OrderPage(items: items, totalCount: data['totalCount'] as int, page: data['page'] as int, pageSize: data['pageSize'] as int);
  }

  static Future<Order> getOrder(String id) async => Order.fromJson(await ApiClient.instance.get('/orders/$id') as Map<String, dynamic>);

  static Future<List<OrderStatusEvent>> getStatusHistory(String id) async {
    final data = await ApiClient.instance.get('/orders/$id/status-history') as List<dynamic>;
    return data.map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> repeatOrder(String id) async {
    await ApiClient.instance.post('/orders/$id/repeat');
  }
}
