import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/api_exception.dart';
import '../services/cart_repository.dart';

/// Корзина, синхронизированная с backend (GET/POST/PUT/DELETE /api/cart).
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  int _totalWeightGrams = 0;
  bool _loading = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _loading;
  String? get error => _error;
  int get itemsCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get totalAmount => _items.fold(0, (sum, i) => sum + i.total);
  int get totalWeightGrams => _totalWeightGrams;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await CartRepository.getCart();
      _items = data.items;
      _totalWeightGrams = data.totalWeightGrams;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Не удалось загрузить корзину';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addVariant(String productVariantId, {int quantity = 1}) async {
    final data = await CartRepository.addItem(productVariantId, quantity);
    _items = data.items;
    _totalWeightGrams = data.totalWeightGrams;
    _error = null;
    notifyListeners();
  }

  Future<void> updateQuantity(int index, int quantity) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    if (quantity <= 0) {
      await remove(index);
      return;
    }
    await CartRepository.updateQuantity(item.id, quantity);
    await load();
  }

  Future<void> remove(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    await CartRepository.removeItem(item.id);
    await load();
  }

  Future<void> clear() async {
    await CartRepository.clear();
    _items = [];
    _totalWeightGrams = 0;
    notifyListeners();
  }
}
