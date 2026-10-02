import '../models/product.dart';
import 'api_client.dart';

class FavoritesRepository {
  FavoritesRepository._();

  static Future<List<Product>> getFavorites() async {
    final data = await ApiClient.instance.get('/favorites') as List<dynamic>;
    return data.map((e) => Product.fromListItemJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> add(String productId) async {
    await ApiClient.instance.post('/favorites/$productId');
  }

  static Future<void> remove(String productId) async {
    await ApiClient.instance.delete('/favorites/$productId');
  }
}
