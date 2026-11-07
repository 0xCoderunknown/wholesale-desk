import '../services/scheme_helper.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get lineTotalPtr => product.ptr * quantity;
  double get lineTotalMrp => product.mrp * quantity;
  double get lineSavings => lineTotalMrp - lineTotalPtr;

  bool get hasScheme => product.scheme.trim().isNotEmpty;

  /// Carton box equivalent display (e.g. "≈ 2 Box(es)")
  String get boxCountDisplay {
    if (!product.hasCartonPack) return '';
    final boxes = (quantity / product.cartonPack).toStringAsFixed(1).replaceAll('.0', '');
    return '≈ $boxes Box(es)';
  }

  /// Real-time scheme nudge and margin boost calculations
  SchemeNudge get nudge => SchemeHelper.calculateNudge(
        scheme: product.scheme,
        currentQuantity: quantity,
        ptr: product.ptr,
        mrp: product.mrp,
      );

  /// Scheme threshold quantity required to earn bonus units
  int get schemeThreshold => SchemeHelper.parseThreshold(product.scheme);
}

