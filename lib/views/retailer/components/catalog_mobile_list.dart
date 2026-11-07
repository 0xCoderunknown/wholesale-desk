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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return MobileProductListItem(
          product: products[index],
          enforceMoq: enforceMoq,
        );
      },
    );
  }
}

class MobileProductListItem extends StatelessWidget {
  final Product product;
  final bool enforceMoq;

  const MobileProductListItem({
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
      color: inCart ? AppTheme.primarySurface.withValues(alpha: 0.5) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductAvatar(
                  name: product.name,
                  brand: product.brand,
                  size: 38,
                  fontSize: 16,
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
                          fontWeight: FontWeight.w500,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StockTogglePill(
                  inStock: product.inStock,
                  enabled: false,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Scheme, 1-Tap Auto-Fill, MOQ & Box Pack Badges
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (product.scheme.trim().isNotEmpty) ...[
                  SchemeBadge(scheme: product.scheme),
                  if (schemeThreshold > 0 && product.inStock)
                    SchemeApplyPill(
                      threshold: schemeThreshold,
                      isAlreadyActive: inCart && qty >= schemeThreshold,
                      onApply: () => cart.applyScheme(product, schemeThreshold, enforceMoq: enforceMoq),
                    ),
                ],
                MoqBadge(moq: product.moq),
                if (product.hasCartonPack) BoxPackBadge(cartonPack: product.cartonPack),
              ],
            ),

            // Upselling Nudge with Real-Time Distance Micro-Copy
            if (nudge.hasScheme && nudge.message.isNotEmpty) ...[
              const SizedBox(height: 6),
              SchemeNudgePill(
                message: nudge.message,
                isQualified: nudge.isQualified,
              ),
            ],

            const SizedBox(height: 10),

            // Rates & Action Row (with Boosted Margin & Direct Delete)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppFormatters.formatCurrency(product.ptr),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    MarginBoostBadge(
                      baseMargin: product.marginPercent,
                      effectiveMargin: nudge.effectiveMarginPercent,
                      effectivePtr: nudge.effectivePtr,
                      isBoosted: nudge.hasBoostedMargin,
                    ),
                  ],
                ),

                // Add / Stepper with Direct ✕ Zero-Reset
                if (product.inStock)
                  inCart
                      ? CatalogQuantityStepper(
                          product: product,
                          quantity: qty,
                          enforceMoq: enforceMoq,
                          style: StepperStyle.compact,
                          onIncrement: () => cart.increment(product.id),
                          onDecrement: () => cart.decrement(product.id, enforceMoq: enforceMoq),
                          onDirectDelete: () => cart.removeItem(product.id),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => cart.addItem(product, enforceMoq: enforceMoq),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                          label: const Text('Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        )
                else
                  const Text(
                    'Out of Stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.slate400,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

