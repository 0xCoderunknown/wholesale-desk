import 'package:flutter/material.dart';
import '../../../config/breakpoints.dart';
import '../../../models/product.dart';
import 'product_card_tile.dart';

export 'product_card_tile.dart';

class CatalogCardGrid extends StatelessWidget {
  final List<Product> products;
  final bool enforceMoq;

  const CatalogCardGrid({
    super.key,
    required this.products,
    required this.enforceMoq,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = AppBreakpoints.isMobile(context);

    // Mobile fallback (< 768px): single item per row using dynamic height list
    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: 84, // Avoid bottom floating cart pill occlusion
        ),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return ProductCardTile(
            product: products[index],
            enforceMoq: enforceMoq,
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth < 1100 ? 2 : (screenWidth < 1400 ? 3 : 4),
        mainAxisExtent: 250,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCardTile(
          product: products[index],
          enforceMoq: enforceMoq,
        );
      },
    );
  }
}
