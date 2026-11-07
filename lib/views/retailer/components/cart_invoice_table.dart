import 'package:flutter/material.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/cart_item.dart';
import '../../../state/cart_provider.dart';
import '../../widgets/catalog_quantity_stepper.dart';
import '../../widgets/high_density_badge.dart';

/// High-density proforma invoice data table for desktop wholesale order review.
class CartInvoiceTable extends StatelessWidget {
  final List<CartItem> items;
  final CartProvider cart;
  final bool enforceMoq;

  const CartInvoiceTable({
    super.key,
    required this.items,
    required this.cart,
    required this.enforceMoq,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(36), // #
            1: FlexColumnWidth(3.0), // Product & Brand
            2: FixedColumnWidth(110), // Rate (PTR/MRP)
            3: FixedColumnWidth(160), // Billed Qty Stepper
            4: FlexColumnWidth(1.8), // Schemes & Bonus
            5: FixedColumnWidth(110), // Line Total
            6: FixedColumnWidth(44), // Action
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: AppTheme.slate100,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              children: [
                _th('#', align: TextAlign.center),
                _th('Product & Specification'),
                _th('Wholesale Rate', align: TextAlign.right),
                _th('Billed Qty', align: TextAlign.center),
                _th('Scheme Status'),
                _th('Line Total (PTR)', align: TextAlign.right),
                _th(''),
              ],
            ),
            for (int i = 0; i < items.length; i++)
              _buildTableRow(items[i], i + 1, isLast: i == items.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _th(String title, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        title,
        textAlign: align,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.slate700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    CartItem item,
    int index, {
    required bool isLast,
  }) {
    final p = item.product;
    final nudge = item.nudge;
    final schemeThreshold = item.schemeThreshold;
    final boxDisplay = item.boxCountDisplay;

    return TableRow(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? const Color(0xFFFAFAFA) : Colors.white,
        border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.slate200, width: 0.8)),
      ),
      children: [
        // 0. Row Index
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Text(
            '$index',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate400),
          ),
        ),

        // 1. Product & Specification
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    p.brand,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.slate500),
                  ),
                  if (p.hasCartonPack) BoxPackBadge(cartonPack: p.cartonPack),
                  if (enforceMoq && p.moq > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.slate100,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: AppTheme.slate300),
                      ),
                      child: Text('MOQ: ${p.moq}', style: const TextStyle(fontSize: 10, color: AppTheme.slate600)),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 2. Rate (Wholesale PTR / MRP)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.formatCurrency(p.ptr),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
              ),
              Text(
                'MRP: ${AppFormatters.formatCurrency(p.mrp)}',
                style: const TextStyle(fontSize: 10.5, color: AppTheme.slate500),
              ),
              if (nudge.hasBoostedMargin)
                Text(
                  'Eff: ${AppFormatters.formatCurrency(nudge.effectivePtr)}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                ),
            ],
          ),
        ),

        // 3. Billed Quantity Stepper
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CatalogQuantityStepper(
                product: p,
                quantity: item.quantity,
                enforceMoq: enforceMoq,
                style: StepperStyle.drawer,
                onIncrement: () => cart.increment(p.id),
                onDecrement: () => cart.decrement(p.id, enforceMoq: enforceMoq),
                onDirectDelete: () => cart.removeItem(p.id),
                onQuantityChanged: (newQty) => cart.updateQuantity(p.id, newQty, enforceMoq: enforceMoq),
              ),
              if (boxDisplay.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  boxDisplay,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                ),
              ],
            ],
          ),
        ),

        // 4. Scheme & Bonus Status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.hasScheme) SchemeBadge(scheme: p.scheme),
              if (nudge.earnedFreeUnits > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    '🎁 +${nudge.earnedFreeUnits} Free (${item.quantity + nudge.earnedFreeUnits}u total)',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                  ),
                ),
              ] else if (item.hasScheme && schemeThreshold > item.quantity) ...[
                const SizedBox(height: 4),
                SchemeApplyPill(
                  threshold: schemeThreshold,
                  isAlreadyActive: false,
                  onApply: () => cart.applyScheme(p, schemeThreshold, enforceMoq: enforceMoq),
                ),
              ],
            ],
          ),
        ),

        // 5. Line Total (PTR) & Margin
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.formatCurrency(item.lineTotalPtr),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
              ),
              Text(
                '+ ${AppFormatters.formatCurrency(item.lineSavings)} margin',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
              ),
            ],
          ),
        ),

        // 6. Action: 1-Tap Delete
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.outOfStockRed),
            tooltip: 'Remove product',
            onPressed: () => cart.removeItem(p.id),
          ),
        ),
      ],
    );
  }
}

