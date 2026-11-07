import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/product.dart';

enum StepperStyle {
  compact,
  fullWidth,
  drawer,
}

/// Canonical, unified quantity stepper with direct zero-reset and MOQ boundary handling.
class CatalogQuantityStepper extends StatelessWidget {
  final Product product;
  final int quantity;
  final bool enforceMoq;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDirectDelete;
  final StepperStyle style;

  const CatalogQuantityStepper({
    super.key,
    required this.product,
    required this.quantity,
    required this.enforceMoq,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDirectDelete,
    this.style = StepperStyle.compact,
  });

  @override
  Widget build(BuildContext context) {
    final minBound = product.minOrderQuantity(enforceMoq: enforceMoq);
    final isAtMinBound = quantity <= minBound;

    if (style == StepperStyle.fullWidth) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.primary, width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: onDecrement,
              onLongPress: onDirectDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Icon(
                  isAtMinBound ? Icons.delete_outline_rounded : Icons.remove_rounded,
                  size: 16,
                  color: isAtMinBound ? AppTheme.outOfStockRed : AppTheme.slate700,
                ),
              ),
            ),
            Text(
              '$quantity Units',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.slate900,
              ),
            ),
            InkWell(
              onTap: onIncrement,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
              ),
            ),
            // Direct 1-Tap Zero-Reset Target
            InkWell(
              onTap: onDirectDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppTheme.slate200)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppTheme.outOfStockRed,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (style == StepperStyle.drawer) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.slate300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onDecrement,
              onLongPress: onDirectDelete,
              child: Container(
                padding: const EdgeInsets.all(5),
                child: Icon(
                  isAtMinBound ? Icons.delete_outline_rounded : Icons.remove_rounded,
                  size: 15,
                  color: isAtMinBound ? AppTheme.outOfStockRed : AppTheme.slate700,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 36),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
            ),
            InkWell(
              onTap: onIncrement,
              child: Container(
                padding: const EdgeInsets.all(5),
                child: const Icon(Icons.add_rounded, size: 15, color: AppTheme.primary),
              ),
            ),
          ],
        ),
      );
    }

    // Default: StepperStyle.compact
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.primary, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onDecrement,
                onLongPress: onDirectDelete,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(
                    isAtMinBound ? Icons.delete_outline_rounded : Icons.remove_rounded,
                    size: 15,
                    color: isAtMinBound ? AppTheme.outOfStockRed : AppTheme.slate700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
              InkWell(
                onTap: onIncrement,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Icons.add_rounded, size: 15, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Direct 1-Tap Zero-Reset Icon
        Tooltip(
          message: 'Zero out / Remove from cart',
          child: InkWell(
            onTap: onDirectDelete,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.slate300, width: 0.8),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppTheme.outOfStockRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

