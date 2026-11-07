import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../state/desk_provider.dart';

class CatalogFilterToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final bool isGridView;
  final bool isDesktop;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleViewMode;
  final List<String> brands;
  final String selectedBrand;
  final ValueChanged<String> onBrandSelected;
  final StockFilterType stockFilter;
  final ValueChanged<StockFilterType> onStockFilterSelected;

  const CatalogFilterToolbar({
    super.key,
    required this.searchController,
    required this.searchFocus,
    required this.isGridView,
    required this.isDesktop,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleViewMode,
    required this.brands,
    required this.selectedBrand,
    required this.onBrandSelected,
    required this.stockFilter,
    required this.onStockFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      // Mobile (< 768px): Single compact horizontal row (saves ~55px vertical space)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.slate200)),
        ),
        child: Row(
          children: [
            // Search Input: flex: 1
            Expanded(
              child: TextField(
                controller: searchController,
                focusNode: searchFocus,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppTheme.slate500),
                  hintText: 'Search products...',
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 15),
                          onPressed: onClearSearch,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Stock Filter: Compact dropdown taking ~110px
            SizedBox(
              width: 112,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.slate300),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StockFilterType>(
                    isExpanded: true,
                    value: stockFilter,
                    icon: const Icon(Icons.filter_list_rounded, size: 15),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.slate800,
                    ),
                    items: const [
                      DropdownMenuItem(value: StockFilterType.all, child: Text('All Stock')),
                      DropdownMenuItem(value: StockFilterType.inStock, child: Text('In Stock')),
                      DropdownMenuItem(value: StockFilterType.outOfStock, child: Text('Out of Stock')),
                    ],
                    onChanged: (v) {
                      if (v != null) onStockFilterSelected(v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.slate200)),
      ),
      child: Row(
        children: [
          // Instant In-Memory Search
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocus,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.slate500),
                hintText: 'Search products by name, brand, or scheme (0ms latency)...',
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: onClearSearch,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // View Mode Switcher (Cards vs List)
          Tooltip(
            message: isGridView ? 'Switch to List View' : 'Switch to Thumbnail Cards',
            child: OutlinedButton.icon(
              onPressed: onToggleViewMode,
              icon: Icon(
                isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                size: 16,
                color: AppTheme.slate700,
              ),
              label: Text(
                isGridView ? 'List' : 'Cards',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate700),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                side: const BorderSide(color: AppTheme.slate300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Desktop Brand Filter
          if (isDesktop) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.slate300),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBrand,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate800,
                  ),
                  items: brands.map((b) {
                    return DropdownMenuItem(value: b, child: Text(b));
                  }).toList(),
                  onChanged: (b) {
                    if (b != null) onBrandSelected(b);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Stock Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.slate300),
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<StockFilterType>(
                value: stockFilter,
                icon: const Icon(Icons.filter_list_rounded, size: 16),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate800,
                ),
                items: const [
                  DropdownMenuItem(value: StockFilterType.all, child: Text('All Stock')),
                  DropdownMenuItem(value: StockFilterType.inStock, child: Text('In Stock Only')),
                  DropdownMenuItem(value: StockFilterType.outOfStock, child: Text('Out of Stock Only')),
                ],
                onChanged: (v) {
                  if (v != null) onStockFilterSelected(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

