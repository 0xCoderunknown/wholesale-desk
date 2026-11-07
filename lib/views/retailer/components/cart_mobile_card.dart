import 'package:flutter/material.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/cart_item.dart';
import '../../../state/cart_provider.dart';
import '../../widgets/catalog_quantity_stepper.dart';
import '../../widgets/high_density_badge.dart';

/// Single item card component for mobile cart review flow.
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
    final schemeThreshold = item.schemeThreshold;
    final boxDisplay = item.boxCountDisplay;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title, Line Total & Delete Target
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                    ),
                    const SizedBox(height: 2),
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
                        if (item.hasScheme) SchemeBadge(scheme: p.scheme),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatCurrency(item.lineTotalPtr),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                  ),
                  Text(
                    'MRP: ${AppFormatters.formatCurrency(item.lineTotalMrp)}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.outOfStockRed),
                tooltip: 'Remove',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => cart.removeItem(p.id),
              ),
            ],
          ),

          // Bonus Free Goods indicator
          if (nudge.earnedFreeUnits > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Text(
                '🎁 +${nudge.earnedFreeUnits} Free Units (Total: ${item.quantity + nudge.earnedFreeUnits}u)',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
              ),
            ),
          ] else if (item.hasScheme && schemeThreshold > item.quantity) ...[
            const SizedBox(height: 6),
            SchemeApplyPill(
              threshold: schemeThreshold,
              isAlreadyActive: false,
              onApply: () => cart.applyScheme(p, schemeThreshold, enforceMoq: enforceMoq),
            ),
          ],

          const Divider(height: 14),

          // Bottom Stepper & Rate row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enforceMoq ? 'PTR: ${AppFormatters.formatCurrency(p.ptr)} (MOQ: ${p.moq})' : 'PTR: ${AppFormatters.formatCurrency(p.ptr)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (boxDisplay.isNotEmpty)
                      Text(
                        boxDisplay,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
            ],
          ),
        ],
      ),
    );
  }
}

