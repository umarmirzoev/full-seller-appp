import 'package:flutter/foundation.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _productIds = {};

  bool isFavorite(String productId) => _productIds.contains(productId);
  int get count => _productIds.length;
  Set<String> get productIds => Set.unmodifiable(_productIds);

  void toggle(String productId) {
    if (_productIds.contains(productId)) {
      _productIds.remove(productId);
    } else {
      _productIds.add(productId);
    }
    notifyListeners();
  }
}
