import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemsCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get totalAmount => _items.fold(0, (sum, i) => sum + i.total);
  int get totalWeightGrams => _items.fold(0, (sum, i) => sum + i.totalWeightGrams);

  void add(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.productId == item.productId && i.variantLabel == item.variantLabel);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
    notifyListeners();
  }

  void remove(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
