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

  /// Packaging trade nomenclature display (e.g. "12 Loose", "1 Box", "1 Box + 4 Loose")
  String get packagingDisplay {
    if (!product.hasCartonPack) return '$quantity Loose';
    final fullBoxes = quantity ~/ product.cartonPack;
    final loose = quantity % product.cartonPack;
    if (fullBoxes == 0) return '$loose Loose';
    if (loose == 0) return '$fullBoxes ${fullBoxes == 1 ? 'Box' : 'Boxes'}';
    return '$fullBoxes ${fullBoxes == 1 ? 'Box' : 'Boxes'} + $loose Loose';
  }

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

