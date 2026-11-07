import 'package:flutter/material.dart';
import '../../../services/scheme_helper.dart';
import '../../../state/cart_provider.dart';

/// Real-time actionable strip notifying the retailer of items close to scheme thresholds.
class CartSchemeMaximizer extends StatelessWidget {
  final CartProvider cart;
  final bool enforceMoq;

  const CartSchemeMaximizer({
    super.key,
    required this.cart,
    required this.enforceMoq,
  });

  @override
  Widget build(BuildContext context) {
    final nearItems = cart.itemsNearScheme;
    if (nearItems.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFEF3C7), // Amber 100
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${nearItems.length} item(s) are within reach of Free Bonus Units! Tap [Top-up] to maximize margin.',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 6,
            children: nearItems.take(2).map((it) {
              final threshold = SchemeHelper.parseThreshold(it.product.scheme);
              final diff = threshold - it.quantity;
              return ActionChip(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFF59E0B)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                labelPadding: EdgeInsets.zero,
                label: Text(
                  '+$diff ${it.product.name.split(' ').first} [Free Bonus]',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                ),
                onPressed: () => cart.applyScheme(it.product, threshold, enforceMoq: enforceMoq),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

