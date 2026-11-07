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
import '../../widgets/scheme_accordion.dart';

/// Canonical, high-density product card component used across mobile list and desktop grid.
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

    // MRP and PTR share the exact same font size and default color; PTR turns vibrant green when discounted.
    final bool isPtrChanged = nudge.hasBoostedMargin && nudge.effectivePtr < product.ptr;
    final double displayPtr = isPtrChanged ? nudge.effectivePtr : product.ptr;
    const double priceFontSize = 14.5;
    const FontWeight priceFontWeight = FontWeight.w700;
    const Color basePriceColor = AppTheme.slate800;

    return Card(
      elevation: inCart ? 2 : 0,
      color: inCart ? AppTheme.primarySurface.withValues(alpha: 0.45) : Colors.white,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Monogram Avatar & Product Title
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Metadata Badges (MOQ & Box Pack, dimmed if OOS)
            Opacity(
              opacity: product.inStock ? 1.0 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoqBadge(moq: product.moq),
                  if (product.hasCartonPack) ...[
                    const SizedBox(width: 6),
                    BoxPackBadge(cartonPack: product.cartonPack),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Unified Price & Margin Bar: [₹MRP_VALUE  [MARGIN: XYZ%]  ₹PTR_VALUE]
            // Note: MRP and PTR share the exact same font size and default color; PTR turns green when discounted.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: MRP Value
                  Text(
                    AppFormatters.formatCurrency(product.mrp),
                    style: const TextStyle(
                      fontSize: priceFontSize,
                      fontWeight: priceFontWeight,
                      color: basePriceColor,
                    ),
                  ),
                  // Center: Margin Badge
                  Flexible(
                    child: MarginBoostBadge(
                      baseMargin: product.marginPercent,
                      effectiveMargin: nudge.effectiveMarginPercent,
                      effectivePtr: nudge.effectivePtr,
                      isBoosted: nudge.hasBoostedMargin,
                    ),
                  ),
                  // Right: Wholesale Rate / PTR Value (Same font size & color as MRP by default, green when value changes)
                  Text(
                    AppFormatters.formatCurrency(displayPtr),
                    style: TextStyle(
                      fontSize: priceFontSize,
                      fontWeight: priceFontWeight,
                      color: isPtrChanged
                          ? const Color(0xFF059669) // Vibrant emerald green when value changes
                          : basePriceColor, // Exact same color as MRP by default
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Dual Action Row: In-place stepper replacement with Buy 1 Box adjacent
            if (product.inStock)
              Row(
                children: [
                  // Primary Action / Stepper slot
                  Expanded(
                    child: inCart
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
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                            label: const Text(
                              'Add to Cart',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                  ),
                  // Bulk Quick-Buy: 1-Tap Carton/Box Buy
                  if (product.hasCartonPack) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => cart.buyBox(product, enforceMoq: enforceMoq),
                        icon: const Icon(Icons.inventory_2_outlined, size: 15, color: Color(0xFF2563EB)),
                        label: Text(
                          'Buy 1 Box (${product.cartonPack})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          side: const BorderSide(color: Color(0xFF93C5FD), width: 1.2),
                          backgroundColor: const Color(0xFFEFF6FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
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

            // Relocate Scheme Details to Collapsible Accordion (Shikhar Style)
            if (product.scheme.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              SchemeCollapsibleAccordion(
                product: product,
                inStock: product.inStock,
                isAlreadyActive: nudge.isQualified,
                onApplyScheme: () => cart.applyScheme(product, schemeThreshold, enforceMoq: enforceMoq),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

