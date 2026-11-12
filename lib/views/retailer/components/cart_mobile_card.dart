import 'package:material_ui/material_ui.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/cart_item.dart';
import '../../../state/cart_provider.dart';
import '../../widgets/catalog_quantity_stepper.dart';

/// Streamlined mobile cart card.
/// Renders: Title & Brand, Rate, Action Row ([ - 12 + ] | Scheme Badge 🎁 | Line: ₹... | [ 🗑 ]).
class CartMobileCard extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;
  final bool enforceMoq;

  const CartMobileCard({
    super.key,
    required this.item,
    required this.cart,
    required this.enforceMoq,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final nudge = item.nudge;
    final titleBrand = p.brand.isNotEmpty ? '${p.name} (${p.brand})' : p.name;
    final hasScheme = p.scheme.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title & Brand
          Text(
            titleBrand,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
          ),
          const SizedBox(height: 3),

          // 2. Rate: PTR
          Text(
            'PTR: ${AppFormatters.formatCurrency(p.ptr)}',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.slate600),
          ),
          const SizedBox(height: 8),

          // 3. Action Row: [ - 12 + ] stepper | Compact badge: 12+1 Free 🎁 | Line: ₹3,420.00 | [ 🗑 ]
          Row(
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
              if (hasScheme) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: nudge.earnedFreeUnits > 0
                            ? const Color(0xFF166534)
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        AppFormatters.formatCurrency(item.lineTotalPtr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => cart.removeItem(p.id),
                        borderRadius: BorderRadius.circular(6),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppTheme.outOfStockRed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
