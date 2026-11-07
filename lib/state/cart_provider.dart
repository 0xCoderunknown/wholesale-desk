import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/scheme_helper.dart';

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

  /// Total full cartons across all items with defined cartonPack
  int get totalBoxes => _items.values.fold(0, (sum, it) {
        final cp = it.product.cartonPack;
        return cp > 0 ? sum + (it.quantity ~/ cp) : sum;
      });

  /// Total loose units that do not complete a full carton
  int get totalLooseUnits => _items.values.fold(0, (sum, it) {
        final cp = it.product.cartonPack;
        return cp > 0 ? sum + (it.quantity % cp) : sum + it.quantity;
      });

  /// Total bonus units earned from all active schemes
  int get totalEarnedFreeUnits => _items.values.fold(0, (sum, it) {
        final n = SchemeHelper.calculateNudge(
          scheme: it.product.scheme,
          currentQuantity: it.quantity,
          ptr: it.product.ptr,
          mrp: it.product.mrp,
        );
        return sum + n.earnedFreeUnits;
      });

  /// Monetary value of free goods evaluated at PTR
  double get totalFreeGoodsValue => _items.values.fold(0.0, (sum, it) {
        final n = SchemeHelper.calculateNudge(
          scheme: it.product.scheme,
          currentQuantity: it.quantity,
          ptr: it.product.ptr,
          mrp: it.product.mrp,
        );
        return sum + (n.earnedFreeUnits * it.product.ptr);
      });

  /// Items in cart that are close (1-3 units) to unlocking free goods
  List<CartItem> get itemsNearScheme => _items.values.where((it) {
        final threshold = SchemeHelper.parseThreshold(it.product.scheme);
        if (threshold <= 0) return false;
        final diff = threshold - it.quantity;
        return diff > 0 && diff <= 3;
      }).toList();

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

      // Allow decrementing down to MOQ (or 1 if enforceMoq is false)
      if (item.quantity > minBound) {
        item.quantity -= 1;
        notifyListeners();
      } else if (!enforceMoq && item.quantity <= 1) {
        // When MOQ is not enforced, decrementing at 1 removes the item
        _items.remove(productId);
        notifyListeners();
      }
    }
  }

  void updateQuantity(String productId, int newQuantity, {bool enforceMoq = true}) {
    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      final minBound = (enforceMoq && item.product.moq > 0) ? item.product.moq : 1;

      if (newQuantity <= 0) {
        _items.remove(productId);
      } else if (enforceMoq && newQuantity < minBound) {
        // Enforce MOQ floor when set by hand
        item.quantity = minBound;
      } else {
        item.quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  /// 1-Tap direct scheme auto-fill.
  /// If not in cart or below threshold, sets quantity to [thresholdQuantity].
  /// If already at or above threshold, does NOT double; leaves retailer in control.
  void applyScheme(Product product, int thresholdQuantity, {bool enforceMoq = true}) {
    if (!product.inStock || thresholdQuantity <= 0) return;

    if (_items.containsKey(product.id)) {
      final current = _items[product.id]!.quantity;
      if (current < thresholdQuantity) {
        _items[product.id]!.quantity = thresholdQuantity;
        notifyListeners();
      }
      // If already at or above threshold, do not double!
    } else {
      _items[product.id] = CartItem(
        product: product,
        quantity: thresholdQuantity,
      );
      notifyListeners();
    }
  }

  /// 1-Tap carton/box quick-buy.
  /// Sets quantity directly to 1 box (product.cartonPack). Does NOT double if already in cart.
  void buyBox(Product product, {bool enforceMoq = true}) {
    if (!product.inStock || product.cartonPack <= 0) return;

    if (_items.containsKey(product.id)) {
      final current = _items[product.id]!.quantity;
      if (current < product.cartonPack) {
        _items[product.id]!.quantity = product.cartonPack;
        notifyListeners();
      }
      // If already at or above 1 box, do not double!
    } else {
      _items[product.id] = CartItem(
        product: product,
        quantity: product.cartonPack,
      );
      notifyListeners();
    }
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
