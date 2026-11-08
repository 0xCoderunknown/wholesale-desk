import '../services/scheme_helper.dart';
import 'packaging_helper.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  /// Effective unit billing rate (PTR) respecting percentage discount schemes
  double get effectiveRate {
    final parsed = SchemeHelper.parse(product.scheme);
    if (parsed.type == SchemeType.percentage && parsed.percentDiscount > 0) {
      final discounted = product.ptr * (1.0 - (parsed.percentDiscount / 100.0));
      return discounted < 0.0 ? 0.0 : discounted;
    }
    return product.ptr;
  }

  double get lineTotalPtr => effectiveRate * quantity;
  double get lineTotalMrp => product.mrp * quantity;
  double get lineSavings => lineTotalMrp - lineTotalPtr;

  bool get hasScheme => product.scheme.trim().isNotEmpty;

  /// Packaging trade nomenclature display (e.g. "12 Loose", "1 Box", "1 Box + 4 Loose")
  String get packagingDisplay => PackagingHelper.calculate(
        quantity: quantity,
        cartonPack: product.cartonPack,
      ).tradeNomenclature;

  /// Carton box equivalent display (clean trade nomenclature)
  String get boxCountDisplay => packagingDisplay;

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

