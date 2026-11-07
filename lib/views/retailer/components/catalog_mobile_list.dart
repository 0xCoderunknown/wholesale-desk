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
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 84), // Avoid FAB occlusion
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

            // Rates & Action Row (with Clean Margin Chip & Direct Delete)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
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
                      const SizedBox(height: 2),
                      MarginBoostBadge(
                        baseMargin: product.marginPercent,
                        effectiveMargin: nudge.effectiveMarginPercent,
                        effectivePtr: nudge.effectivePtr,
                        isBoosted: nudge.hasBoostedMargin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Stepper if in cart
                if (product.inStock && inCart)
                  CatalogQuantityStepper(
                    product: product,
                    quantity: qty,
                    enforceMoq: enforceMoq,
                    style: StepperStyle.compact,
                    onIncrement: () => cart.increment(product.id),
                    onDecrement: () => cart.decrement(product.id, enforceMoq: enforceMoq),
                    onDirectDelete: () => cart.removeItem(product.id),
                  ),
              ],
            ),

            // Dual Action Buttons when not in cart
            if (product.inStock && !inCart) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => cart.addItem(product, enforceMoq: enforceMoq),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                      label: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  if (product.hasCartonPack) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => cart.buyBox(product, enforceMoq: enforceMoq),
                        icon: const Icon(Icons.inventory_2_outlined, size: 15, color: Color(0xFF2563EB)),
                        label: Text(
                          'Buy 1 Box (${product.cartonPack})',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF1E40AF)),
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
              ),
            ] else if (!product.inStock) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
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
            ],

            // Relocate Scheme Details to Collapsible Accordion (Shikhar Style)
            if (product.scheme.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              SchemeCollapsibleAccordion(
                product: product,
                inStock: product.inStock,
                isAlreadyActive: inCart && qty >= schemeThreshold,
                onApplyScheme: () => cart.applyScheme(product, schemeThreshold, enforceMoq: enforceMoq),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
