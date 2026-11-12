import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/product.dart';
import '../../../state/desk_provider.dart';
import '../../widgets/stock_toggle_pill.dart';

/// Warehouse Godown Data Table for Staff Role.
/// Strictly shields rates, margins, and schemes.
/// Prioritizes high-contrast box pack metadata and fast 1-tap stock toggles.
class DistributorStaffTable extends StatelessWidget {
  final ValueChanged<Product> onOpenBoxCalculator;

  const DistributorStaffTable({
    super.key,
    required this.onOpenBoxCalculator,
  });

  @override
  Widget build(BuildContext context) {
    final desk = context.watch<DeskProvider>();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 680),
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              horizontalMargin: 16,
              columnSpacing: 18,
              headingRowColor: WidgetStateProperty.all(AppTheme.slate100),
              columns: const [
                DataColumn(
                  label: Text('PRODUCT / BRAND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('BOX / CASE PACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('STOCK AVAILABILITY (CLICK TO TOGGLE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
              rows: desk.filteredProducts.map((p) {
                return DataRow(
                  cells: [
                    // Product & Brand
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tooltip(
                              message: p.name,
                              child: Text(
                                p.name,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              p.brand,
                              style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Box / Case Pack: Large high-contrast text & quick calculator trigger
                    DataCell(
                      InkWell(
                        onTap: () => onOpenBoxCalculator(p),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF), // Blue 50
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF93C5FD), width: 1.2), // Blue 300
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.hasCartonPack ? '📦 Box of ${p.cartonPack}' : '📦 Loose Only',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: p.hasCartonPack ? const Color(0xFF1E40AF) : AppTheme.slate500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Stock Pill: In-Place Toggle (Available for Staff)
                    DataCell(
                      StockTogglePill(
                        inStock: p.inStock,
                        enabled: true,
                        onToggle: () => desk.toggleStock(p.id, !p.inStock),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

