import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/product.dart';
import '../../../state/desk_provider.dart';
import '../../widgets/high_density_badge.dart';
import '../../widgets/stock_toggle_pill.dart';

/// High-Density Mobile Card for Distributor Desk.
/// Renders commercial edit controls for Admin, and rate-shielded box picking card for Staff.
class DistributorMobileCard extends StatelessWidget {
  final Product product;
  final bool isAdmin;
  final ValueChanged<Product> onOpenBoxCalculator;
  final ValueChanged<Product>? onEditProduct;
  final ValueChanged<Product>? onDeleteProduct;

  const DistributorMobileCard({
    super.key,
    required this.product,
    required this.isAdmin,
    required this.onOpenBoxCalculator,
    this.onEditProduct,
    this.onDeleteProduct,
  });

  @override
  Widget build(BuildContext context) {
    final desk = context.watch<DeskProvider>();
    final p = product;

    if (!isAdmin) {
      // Staff Warehouse Mobile Card: Rate Shielded & 1-Line Action Row (Box Calculator & Stock Toggle)
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: p.inStock ? AppTheme.slate200 : AppTheme.outOfStockRed.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Product Name & Brand
              Text(
                p.name,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.slate900),
              ),
              const SizedBox(height: 2),
              Text(p.brand, style: const TextStyle(fontSize: 11.5, color: AppTheme.slate500)),
              const SizedBox(height: 10),

              // Row 2: Box Pack Badge & Stock Toggle in 1 Single Line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Box Pack Badge (Tap to calculate breakdown)
                  InkWell(
                    onTap: () => onOpenBoxCalculator(p),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.hasCartonPack ? '📦 Box of ${p.cartonPack}' : '📦 Loose Only',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: p.hasCartonPack ? const Color(0xFF1E40AF) : AppTheme.slate500,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Stock Toggle Pill
                  StockTogglePill(
                    inStock: p.inStock,
                    enabled: true,
                    onToggle: () => desk.toggleStock(p.id, !p.inStock),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Admin Mobile Card (Full pricing and edit controls)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Text(p.brand, style: const TextStyle(fontSize: 11, color: AppTheme.slate500)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stock toggle pill
                StockTogglePill(
                  inStock: p.inStock,
                  enabled: true,
                  onToggle: () => desk.toggleStock(p.id, !p.inStock),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (p.scheme.trim().isNotEmpty)
                  SchemeBadge(scheme: p.scheme),
                MoqBadge(moq: p.moq),
                if (p.hasCartonPack)
                  InkWell(
                    onTap: () => onOpenBoxCalculator(p),
                    borderRadius: BorderRadius.circular(4),
                    child: BoxPackBadge(cartonPack: p.cartonPack),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'PTR: ${AppFormatters.formatCurrency(p.ptr)} (MRP: ${AppFormatters.formatCurrency(p.mrp)})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEditProduct != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        onPressed: () => onEditProduct!(p),
                      ),
                    if (onDeleteProduct != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.outOfStockRed),
                        onPressed: () => onDeleteProduct!(p),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

