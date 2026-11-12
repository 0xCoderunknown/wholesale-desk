import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/product.dart';
import '../../../state/desk_provider.dart';
import '../../widgets/high_density_badge.dart';
import '../../widgets/stock_toggle_pill.dart';

/// Full Commercial Data Table for Admin Desk.
/// Renders rates, margins, scheme editor triggers, and catalog actions.
class DistributorAdminTable extends StatelessWidget {
  final ValueChanged<Product> onEditProduct;
  final ValueChanged<Product> onDeleteProduct;
  final ValueChanged<Product> onOpenBoxCalculator;

  const DistributorAdminTable({
    super.key,
    required this.onEditProduct,
    required this.onDeleteProduct,
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
            constraints: const BoxConstraints(minWidth: 1020),
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
                  label: Text('STOCK STATUS (CLICK TO TOGGLE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('SCHEME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('MOQ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('BOX PACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('MRP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('PTR (RATE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('MARGIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                DataColumn(
                  label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
              rows: desk.filteredProducts.map((p) {
                return DataRow(
                  cells: [
                    // Product & Brand (Zero bloat, no decorative images)
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 300),
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
                              style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Stock Pill: In-Place Toggle
                    DataCell(
                      StockTogglePill(
                        inStock: p.inStock,
                        enabled: true,
                        onToggle: () => desk.toggleStock(p.id, !p.inStock),
                      ),
                    ),

                    // Scheme
                    DataCell(SchemeBadge(scheme: p.scheme)),

                    // MOQ
                    DataCell(MoqBadge(moq: p.moq)),

                    // Box Pack / Carton (Clickable to open calculator)
                    DataCell(
                      p.hasCartonPack
                          ? InkWell(
                              onTap: () => onOpenBoxCalculator(p),
                              borderRadius: BorderRadius.circular(4),
                              child: BoxPackBadge(cartonPack: p.cartonPack),
                            )
                          : const Text('-', style: TextStyle(color: AppTheme.slate400, fontSize: 12)),
                    ),

                    // MRP
                    DataCell(
                      Text(
                        AppFormatters.formatCurrency(p.mrp),
                        style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
                      ),
                    ),

                    // PTR (Rate)
                    DataCell(
                      Text(
                        AppFormatters.formatCurrency(p.ptr),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                      ),
                    ),

                    // Margin
                    DataCell(
                      Text(
                        '+${p.marginPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                      ),
                    ),

                    // Actions (Edit or Delete)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 17, color: AppTheme.slate700),
                            tooltip: 'Edit Rates & Scheme',
                            onPressed: () => onEditProduct(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.outOfStockRed),
                            tooltip: 'Delete Product',
                            onPressed: () => onDeleteProduct(p),
                          ),
                        ],
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

