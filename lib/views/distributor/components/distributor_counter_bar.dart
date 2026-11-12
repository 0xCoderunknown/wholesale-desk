import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../state/desk_provider.dart';

/// Counter Fast Search, Filter & Summary Bar for Distributor Desk.
/// Provides sub-millisecond in-memory search, brand/stock filters,
/// and live counter inventory metrics.
class DistributorCounterBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final bool isAdmin;
  final bool isDesktop;
  final VoidCallback? onAddProduct;
  final VoidCallback onOpenBoxCalculator;

  const DistributorCounterBar({
    super.key,
    required this.searchController,
    required this.searchFocus,
    required this.isAdmin,
    required this.isDesktop,
    this.onAddProduct,
    required this.onOpenBoxCalculator,
  });

  @override
  Widget build(BuildContext context) {
    final desk = context.watch<DeskProvider>();

    return Column(
      children: [
        // Counter Fast Search & Action Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.slate200)),
          ),
          child: Row(
            children: [
              // In-memory instant client search
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocus,
                    onChanged: desk.setSearchQuery,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.slate500),
                      hintText: 'Counter search: product name, brand, or scheme...',
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                searchController.clear();
                                desk.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Brand Selector (Desktop only)
              if (isDesktop) ...[
                SizedBox(
                  height: 38,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.slate300),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isDense: true,
                        value: desk.selectedBrand,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate800),
                        items: desk.brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (b) {
                          if (b != null) desk.setSelectedBrand(b);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Stock Status Filter
              SizedBox(
                height: 38,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.slate300),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StockFilterType>(
                      isDense: true,
                      value: desk.stockFilter,
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate800),
                      items: const [
                        DropdownMenuItem(value: StockFilterType.all, child: Text('All Stock')),
                        DropdownMenuItem(value: StockFilterType.inStock, child: Text('In Stock Only')),
                        DropdownMenuItem(value: StockFilterType.outOfStock, child: Text('Out of Stock Only')),
                      ],
                      onChanged: (v) {
                        if (v != null) desk.setStockFilter(v);
                      },
                    ),
                  ),
                ),
              ),

              // Add Product Button (Admin only)
              if (isAdmin && onAddProduct != null) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: onAddProduct,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(isDesktop ? 'Add Product' : 'Add'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Live Counter Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppTheme.slate50,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isAdmin
                      ? (isDesktop
                          ? 'Showing ${desk.filteredProducts.length} items | Click Green/Red pill to toggle stock instantly'
                          : '${desk.filteredProducts.length} items • 1-tap stock toggle')
                      : (isDesktop
                          ? 'Warehouse Godown Mode | Rate Shield Active | Click Green/Red pill to toggle stock'
                          : 'Godown Mode • Rate Shielded'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isDesktop
                    ? '${desk.inStockCount} In Stock • ${desk.outOfStockCount} Out'
                    : '${desk.inStockCount} In • ${desk.outOfStockCount} Out',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate500),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onOpenBoxCalculator,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF93C5FD), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📦', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 4),
                        Text(
                          'Box Calculator',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

