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

class CatalogDataTable extends StatelessWidget {
  final List<Product> products;
  final bool enforceMoq;

  const CatalogDataTable({
    super.key,
    required this.products,
    required this.enforceMoq,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1080),
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              horizontalMargin: 16,
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(AppTheme.slate100),
              columns: const [
                DataColumn(
                  label: Text('PRODUCT / BRAND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
                DataColumn(
                  label: Text('SCHEME & 1-TAP APPLY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
                DataColumn(
                  label: Text('MOQ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
                DataColumn(
                  label: Text('BOX PACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
                DataColumn(
                  label: Text('MRP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
                DataColumn(
                  label: Text('PTR (RATE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
                DataColumn(
                  label: Text('MARGIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
                DataColumn(
                  label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
                DataColumn(
                  label: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
                ),
              ],
              rows: products.map((p) {
                return _buildRow(context, p, cart);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Product p, CartProvider cart) {
    // Read cart quantity
    final inCart = cart.isInCart(p.id);
    final qty = cart.getQuantity(p.id);
    final schemeThreshold = SchemeHelper.parseThreshold(p.scheme);
    final nudge = SchemeHelper.calculateNudge(
      scheme: p.scheme,
      currentQuantity: inCart ? qty : 0,
      ptr: p.ptr,
      mrp: p.mrp,
    );

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (inCart) return AppTheme.primarySurface.withValues(alpha: 0.4);
        return null;
      }),
      cells: [
        // Product & Brand with Letter Monogram Avatar (Zero media overhead)
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Row(
              children: [
                ProductAvatar(name: p.name, brand: p.brand, size: 34, fontSize: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p.brand,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.slate500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scheme with 1-Tap Auto-Fill & Distance Nudge
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.scheme.trim().isNotEmpty) SchemeBadge(scheme: p.scheme),
                  if (schemeThreshold > 0 && p.inStock) ...[
                    const SizedBox(width: 4),
                    SchemeApplyPill(
                      threshold: schemeThreshold,
                      isAlreadyActive: inCart && qty >= schemeThreshold,
                      onApply: () => cart.applyScheme(p, schemeThreshold, enforceMoq: enforceMoq),
                    ),
                  ],
                ],
              ),
              if (nudge.hasScheme && nudge.message.isNotEmpty) ...[
                const SizedBox(height: 3),
                SchemeNudgePill(
                  message: nudge.message,
                  isQualified: nudge.isQualified,
                ),
              ],
            ],
          ),
        ),

        // MOQ
        DataCell(MoqBadge(moq: p.moq)),

        // Box Pack
        DataCell(
          p.hasCartonPack
              ? BoxPackBadge(cartonPack: p.cartonPack)
              : const Text('-', style: TextStyle(color: AppTheme.slate400, fontSize: 12)),
        ),

        // MRP (Clean text, NO strikethrough)
        DataCell(
          Text(
            AppFormatters.formatCurrency(p.mrp),
            style: const TextStyle(fontSize: 12, color: AppTheme.slate600, fontWeight: FontWeight.w500),
          ),
        ),

        // PTR
        DataCell(
          Text(
            AppFormatters.formatCurrency(p.ptr),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
          ),
        ),

        // Margin % (with Boosted Scheme Indicator)
        DataCell(
          MarginBoostBadge(
            baseMargin: p.marginPercent,
            effectiveMargin: nudge.effectiveMarginPercent,
            effectivePtr: nudge.effectivePtr,
            isBoosted: nudge.hasBoostedMargin,
          ),
        ),

        // Stock Pill (read-only for Retailer)
        DataCell(
          StockTogglePill(inStock: p.inStock, enabled: false, compact: true),
        ),

        // Large Add to Cart Button or Stepper with Direct ✕ Zero-Reset
        DataCell(
          p.inStock
              ? inCart
                  ? CatalogQuantityStepper(
                      product: p,
                      quantity: qty,
                      enforceMoq: enforceMoq,
                      style: StepperStyle.compact,
                      onIncrement: () => cart.increment(p.id),
                      onDecrement: () => cart.decrement(p.id, enforceMoq: enforceMoq),
                      onDirectDelete: () => cart.removeItem(p.id),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => cart.addItem(p, enforceMoq: enforceMoq),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    )
              : const Text(
                  'Out of Stock',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate400),
                ),
        ),
      ],
    );
  }
}

