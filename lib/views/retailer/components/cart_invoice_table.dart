import 'package:flutter/material.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/cart_item.dart';
import '../../../state/cart_provider.dart';
import '../../widgets/catalog_quantity_stepper.dart';

/// Streamlined proforma invoice table for desktop wholesale order review.
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
    return Container(
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
          1: FlexColumnWidth(3.0), // Product & Brand · Box
          2: FixedColumnWidth(95), // PTR Rate
          3: FlexColumnWidth(2.6), // Order Quantity & Scheme
          4: FlexColumnWidth(2.0), // Line Total + Delete
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
              _th('Product & Brand'),
              _th('PTR Rate', align: TextAlign.right),
              _th('Order Quantity & Scheme', align: TextAlign.center),
              _th('Line Total', align: TextAlign.right),
            ],
          ),
          for (int i = 0; i < items.length; i++)
            _buildTableRow(items[i], i + 1, isLast: i == items.length - 1),
        ],
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
    final hasScheme = p.scheme.trim().isNotEmpty;

    return TableRow(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? const Color(0xFFFAFAFA) : Colors.white,
        border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.slate200, width: 0.8)),
      ),
      children: [
        // 0. Row Index
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Text(
            '$index',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate400),
          ),
        ),

        // 1. Product Details: Name, Brand · Box Pack
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                p.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
              ),
              if (p.brand.isNotEmpty || p.cartonPack > 1) ...[
                const SizedBox(height: 3),
                Text(
                  [
                    if (p.brand.isNotEmpty) p.brand,
                    if (p.cartonPack > 1) 'Box: ${p.cartonPack}',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.slate500),
                ),
              ],
            ],
          ),
        ),

        // 2. PTR Rate: ₹285.00 (prefix removed)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(
            AppFormatters.formatCurrency(p.ptr),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.slate800),
          ),
        ),

        // 3. Action: Center aligned [ - 12 + ] stepper | Compact badge: 12+1 Free 🎁
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
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
                if (hasScheme)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: nudge.earnedFreeUnits > 0
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: nudge.earnedFreeUnits > 0
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFCD34D),
                      ),
                    ),
                    child: Text(
                      '${p.scheme}${nudge.earnedFreeUnits > 0 ? ' 🎁' : ''}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: nudge.earnedFreeUnits > 0
                            ? const Color(0xFF166534)
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 4. Line Total: ₹3,420.00 (prefix removed) | [ 🗑 ]
        Padding(
          padding: const EdgeInsets.only(left: 6, top: 8, bottom: 8, right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  AppFormatters.formatCurrency(item.lineTotalPtr),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => cart.removeItem(p.id),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.outOfStockRed),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
