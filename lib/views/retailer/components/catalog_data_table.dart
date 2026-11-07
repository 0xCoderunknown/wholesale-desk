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
            constraints: const BoxConstraints(minWidth: 1040),
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              horizontalMargin: 16,
              columnSpacing: 14,
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
            constraints: const BoxConstraints(maxWidth: 300),
            child: Row(
              children: [
                ProductAvatar(name: p.name, brand: p.brand, size: 34, fontSize: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: p.name,
                        child: Text(
                          p.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                          maxLines: 2,
                        ),
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

        // Scheme Column: side-by-side flex row, dimmed if OOS, micro-copy ONLY if inStock && qty > 0
        DataCell(
          Opacity(
            opacity: p.inStock ? 1.0 : 0.45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.scheme.trim().isNotEmpty) SchemeBadge(scheme: p.scheme),
                    if (p.inStock && schemeThreshold > 0) ...[
                      const SizedBox(width: 4),
                      SchemeApplyPill(
                        threshold: schemeThreshold,
                        isAlreadyActive: inCart && qty >= schemeThreshold,
                        onApply: () => cart.applyScheme(p, schemeThreshold, enforceMoq: enforceMoq),
                      ),
                    ],
                  ],
                ),
                // Micro-copy strictly hidden at qty == 0 or when Out of Stock
                if (p.inStock && qty > 0 && nudge.hasScheme && nudge.message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  SchemeNudgePill(
                    message: nudge.message,
                    isQualified: nudge.isQualified,
                  ),
                ],
              ],
            ),
          ),
        ),

        // MOQ (dimmed if OOS)
        DataCell(
          Opacity(
            opacity: p.inStock ? 1.0 : 0.45,
            child: MoqBadge(moq: p.moq),
          ),
        ),

        // Box Pack (dimmed if OOS)
        DataCell(
          Opacity(
            opacity: p.inStock ? 1.0 : 0.45,
            child: p.hasCartonPack
                ? BoxPackBadge(cartonPack: p.cartonPack)
                : const Text('-', style: TextStyle(color: AppTheme.slate400, fontSize: 12)),
          ),
        ),

        // MRP (Clean text, NO strikethrough)
        DataCell(
          Text(
            AppFormatters.formatCurrency(p.mrp),
            style: const TextStyle(fontSize: 13, color: AppTheme.slate800, fontWeight: FontWeight.w700),
          ),
        ),

        // PTR (Same font size & color as MRP by default, green if value changes)
        DataCell(
          Text(
            AppFormatters.formatCurrency(
              (nudge.hasBoostedMargin && nudge.effectivePtr < p.ptr)
                  ? nudge.effectivePtr
                  : p.ptr,
            ),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: (nudge.hasBoostedMargin && nudge.effectivePtr < p.ptr)
                  ? const Color(0xFF059669)
                  : AppTheme.slate800,
            ),
          ),
        ),

        // Margin %: Clean value chip (+13.6%), stripped redundant 'Retailer Margin:' label
        DataCell(
          MarginBoostBadge(
            baseMargin: p.marginPercent,
            effectiveMargin: nudge.effectiveMarginPercent,
            effectivePtr: nudge.effectivePtr,
            isBoosted: nudge.hasBoostedMargin,
            compact: true,
          ),
        ),

        // Stock Pill (read-only for Retailer)
        DataCell(
          StockTogglePill(inStock: p.inStock, enabled: false, compact: true),
        ),

        // Action Column: Add/Stepper or disabled Out of Stock
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
                      onQuantityChanged: (newQty) => cart.updateQuantity(p.id, newQty, enforceMoq: enforceMoq),
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
