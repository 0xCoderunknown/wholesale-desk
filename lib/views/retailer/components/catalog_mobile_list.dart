import 'package:flutter/material.dart';
import '../../../models/product.dart';
import 'product_card_tile.dart';

export 'product_card_tile.dart';

/// Backward-compatibility typedef pointing to canonical ProductCardTile
typedef MobileProductListItem = ProductCardTile;

class CatalogMobileList extends StatelessWidget {
  final List<Product> products;
  final bool enforceMoq;

  const CatalogMobileList({
    super.key,
    required this.products,
    required this.enforceMoq,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 84), // Avoid FAB occlusion
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return ProductCardTile(
          product: products[index],
          enforceMoq: enforceMoq,
        );
      },
    );
  }
}
