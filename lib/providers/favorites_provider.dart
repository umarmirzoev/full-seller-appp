import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_exception.dart';
import '../services/favorites_repository.dart';

/// Избранное, синхронизированное с backend (GET/POST/DELETE /api/favorites).
class FavoritesProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _loading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _loading;
  String? get error => _error;
  int get count => _products.length;
  Set<String> get productIds => _products.map((p) => p.id).toSet();

  bool isFavorite(String productId) => _products.any((p) => p.id == productId);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _products = await FavoritesRepository.getFavorites();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Не удалось загрузить избранное';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggle(Product product) async {
    final wasFavorite = isFavorite(product.id);
    if (wasFavorite) {
      _products.removeWhere((p) => p.id == product.id);
    } else {
      _products.add(product);
    }
    notifyListeners();
    try {
      if (wasFavorite) {
        await FavoritesRepository.remove(product.id);
      } else {
        await FavoritesRepository.add(product.id);
      }
    } catch (_) {
      if (wasFavorite) {
        _products.add(product);
      } else {
        _products.removeWhere((p) => p.id == product.id);
      }
      notifyListeners();
      rethrow;
    }
  }
}
