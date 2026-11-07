import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.length;

  int get totalUnits =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotalPtr =>
      _items.values.fold(0.0, (sum, item) => sum + item.lineTotalPtr);

  double get totalMrp =>
      _items.values.fold(0.0, (sum, item) => sum + item.lineTotalMrp);

  double get totalSavings => totalMrp - subtotalPtr;

  bool isInCart(String productId) => _items.containsKey(productId);

  int getQuantity(String productId) => _items[productId]?.quantity ?? 0;

  void addItem(Product product, {bool enforceMoq = true}) {
    if (!product.inStock) return;

    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += 1;
    } else {
      final initialQty = (enforceMoq && product.moq > 0) ? product.moq : 1;
      _items[product.id] = CartItem(
        product: product,
        quantity: initialQty,
      );
    }
    notifyListeners();
  }

  void increment(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += 1;
      notifyListeners();
    }
  }

  void decrement(String productId, {bool enforceMoq = true}) {
    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      final minBound = (enforceMoq && item.product.moq > 0) ? item.product.moq : 1;

      if (item.quantity <= minBound) {
        _items.remove(productId);
      } else {
        item.quantity -= 1;
      }
      notifyListeners();
    }
  }

  void updateQuantity(String productId, int newQuantity, {bool enforceMoq = true}) {
    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      final minBound = (enforceMoq && item.product.moq > 0) ? item.product.moq : 1;

      if (newQuantity < minBound) {
        _items.remove(productId);
      } else {
        item.quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  /// 1-Tap direct scheme auto-fill.
  /// If not in cart or below threshold, sets quantity to [thresholdQuantity].
  /// If already at or above threshold, increments by another full scheme slab.
  void applyScheme(Product product, int thresholdQuantity, {bool enforceMoq = true}) {
    if (!product.inStock || thresholdQuantity <= 0) return;

    if (_items.containsKey(product.id)) {
      final current = _items[product.id]!.quantity;
      if (current < thresholdQuantity) {
        _items[product.id]!.quantity = thresholdQuantity;
      } else {
        _items[product.id]!.quantity += thresholdQuantity;
      }
    } else {
      _items[product.id] = CartItem(
        product: product,
        quantity: thresholdQuantity,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
