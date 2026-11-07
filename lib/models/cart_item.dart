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
}

