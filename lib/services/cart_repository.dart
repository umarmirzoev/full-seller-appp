import '../models/cart_item.dart';
import 'api_client.dart';

class CartData {
  final String id;
  final List<CartItem> items;
  final int totalWeightGrams;
  final double itemsTotal;
  const CartData({required this.id, required this.items, required this.totalWeightGrams, required this.itemsTotal});
}

class CartRepository {
  CartRepository._();

  static CartData _fromJson(Map<String, dynamic> json) => CartData(
        id: json['id'] as String,
        items: (json['items'] as List<dynamic>? ?? const []).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
        totalWeightGrams: (json['totalWeightGrams'] as num?)?.toInt() ?? 0,
        itemsTotal: (json['itemsTotal'] as num?)?.toDouble() ?? 0,
      );

  static Future<CartData> getCart() async => _fromJson(await ApiClient.instance.get('/cart') as Map<String, dynamic>);

  static Future<CartData> addItem(String productVariantId, int quantity) async => _fromJson(
      await ApiClient.instance.post('/cart/items', body: {'productVariantId': productVariantId, 'quantity': quantity}) as Map<String, dynamic>);

  static Future<void> updateQuantity(String itemId, int quantity) async {
    await ApiClient.instance.put('/cart/items/$itemId', body: {'quantity': quantity});
  }

  static Future<void> removeItem(String itemId) async {
    await ApiClient.instance.delete('/cart/items/$itemId');
  }

  static Future<void> clear() async {
    await ApiClient.instance.delete('/cart');
  }
}
