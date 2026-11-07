import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/product.dart';
import '../../../services/scheme_helper.dart';
import '../../../state/cart_provider.dart';
import '../../widgets/catalog_quantity_stepper.dart';
import '../../widgets/high_density_badge.dart';
import '../../widgets/product_avatar.dart';
import '../../widgets/stock_toggle_pill.dart';

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
    final isMobile = screenWidth < 600;

    return GridView.builder(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: isMobile ? 84 : 12, // Avoid bottom floating cart pill occlusion on mobile
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile
            ? 1 // Strictly 1 card per line on mobile
            : (screenWidth < 900 ? 2 : (screenWidth < 1250 ? 3 : 4)),
        mainAxisExtent: isMobile ? 265 : 260,
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

class ProductCardTile extends StatelessWidget {
  final Product product;
  final bool enforceMoq;

  const ProductCardTile({
    super.key,
    required this.product,
    required this.enforceMoq,
  });

  @override
  Widget build(BuildContext context) {
    final qty = context.select<CartProvider, int>((c) => c.getQuantity(product.id));
    final inCart = qty > 0;
    final cart = context.read<CartProvider>();

    final schemeThreshold = SchemeHelper.parseThreshold(product.scheme);
    final nudge = SchemeHelper.calculateNudge(
      scheme: product.scheme,
      currentQuantity: inCart ? qty : 0,
      ptr: product.ptr,
      mrp: product.mrp,
    );

    return Card(
      elevation: inCart ? 2 : 0,
      color: inCart ? AppTheme.primarySurface.withValues(alpha: 0.45) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: inCart ? AppTheme.primary : AppTheme.slate200,
          width: inCart ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Monogram Avatar & Stock Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductAvatar(
                  name: product.name,
                  brand: product.brand,
                  size: 40,
                  fontSize: 17,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.brand,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                StockTogglePill(
                  inStock: product.inStock,
                  enabled: false,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Metadata Cluster: Scheme Row + MOQ/Box Row beneath (Dimmed if OOS)
            Opacity(
              opacity: product.inStock ? 1.0 : 0.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Scheme Badge & 1-Tap Apply (only if In-Stock)
                  if (product.scheme.trim().isNotEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SchemeBadge(scheme: product.scheme),
                        if (product.inStock && schemeThreshold > 0) ...[
                          const SizedBox(width: 4),
                          SchemeApplyPill(
                            threshold: schemeThreshold,
                            isAlreadyActive: inCart && qty >= schemeThreshold,
                            onApply: () => cart.applyScheme(product, schemeThreshold, enforceMoq: enforceMoq),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Row 2: MOQ & Box Pack Clustered Beneath
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoqBadge(moq: product.moq),
                      if (product.hasCartonPack) ...[
                        const SizedBox(width: 4),
                        BoxPackBadge(cartonPack: product.cartonPack),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Progressive Micro-Copy (STRICTLY hidden at qty == 0 or when Out of Stock)
            if (product.inStock && inCart && nudge.hasScheme && nudge.message.isNotEmpty) ...[
              const SizedBox(height: 5),
              SchemeNudgePill(
                message: nudge.message,
                isQualified: nudge.isQualified,
              ),
            ],

            const Spacer(),

            // Price and Dynamic Boosted Margin Row (MRP WITHOUT strikethrough)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(product.ptr),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    Text(
                      'MRP: ${AppFormatters.formatCurrency(product.mrp)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: MarginBoostBadge(
                    baseMargin: product.marginPercent,
                    effectiveMargin: nudge.effectiveMarginPercent,
                    effectivePtr: nudge.effectivePtr,
                    isBoosted: nudge.hasBoostedMargin,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Prominent Add to Cart Button or Stepper (Disabled if OOS)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: product.inStock
                  ? inCart
                      ? CatalogQuantityStepper(
                          product: product,
                          quantity: qty,
                          enforceMoq: enforceMoq,
                          style: StepperStyle.fullWidth,
                          onIncrement: () => cart.increment(product.id),
                          onDecrement: () => cart.decrement(product.id, enforceMoq: enforceMoq),
                          onDirectDelete: () => cart.removeItem(product.id),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => cart.addItem(product, enforceMoq: enforceMoq),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        )
                  : Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate400,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
