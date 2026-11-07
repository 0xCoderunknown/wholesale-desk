import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/formatters.dart';
import '../../config/theme.dart';
import '../../models/retailer.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/desk_provider.dart';
import 'cart_drawer.dart';
import 'components/catalog_card_grid.dart';
import 'components/catalog_data_table.dart';
import 'components/catalog_filter_toolbar.dart';
import 'components/catalog_mobile_list.dart';

class RetailerCatalogScreen extends StatefulWidget {
  final Retailer retailer;

  const RetailerCatalogScreen({super.key, required this.retailer});

  @override
  State<RetailerCatalogScreen> createState() => _RetailerCatalogScreenState();
}

class _RetailerCatalogScreenState extends State<RetailerCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openCartDrawer(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 850) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
          child: CartDrawer(retailer: widget.retailer),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final desk = context.watch<DeskProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;
    final enforceMoq = auth.settings.enforceMoq;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.slate100,
      endDrawer: isDesktop ? CartDrawer(retailer: widget.retailer) : null,
      floatingActionButton: screenWidth >= 1024
          ? null
          : Consumer<CartProvider>(
              builder: (context, cart, _) {
                return FloatingActionButton.extended(
                  onPressed: () => _openCartDrawer(context),
                  backgroundColor: cart.itemCount > 0 ? AppTheme.whatsappGreen : AppTheme.slate800,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  icon: Badge(
                    label: Text('${cart.itemCount}'),
                    isLabelVisible: cart.itemCount > 0,
                    backgroundColor: AppTheme.outOfStockRed,
                    child: const Icon(Icons.shopping_cart_rounded, size: 20),
                  ),
                  label: Text(
                    cart.itemCount > 0
                        ? '${AppFormatters.formatCurrency(cart.subtotalPtr)} • Cart'
                        : 'Cart',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                );
              },
            ),
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    auth.settings.storeName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Text(
                        'Verified Retailer: ',
                        style: TextStyle(fontSize: 11, color: AppTheme.slate400),
                      ),
                      Flexible(
                        child: Text(
                          widget.retailer.storeName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Route Badge on header
          if (isDesktop && widget.retailer.route.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.slate800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.slate700),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.slate400),
                    const SizedBox(width: 4),
                    Text(
                      widget.retailer.route,
                      style: const TextStyle(fontSize: 11, color: AppTheme.slate200),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),

          // Header Cart Action with Consumer (Isolates rebuilds)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                return ElevatedButton.icon(
                  onPressed: () => _openCartDrawer(context),
                  icon: Badge(
                    label: Text('${cart.itemCount}'),
                    isLabelVisible: cart.itemCount > 0,
                    backgroundColor: AppTheme.outOfStockRed,
                    child: const Icon(Icons.shopping_cart_outlined, size: 17),
                  ),
                  label: Text(
                    cart.subtotalPtr > 0 ? AppFormatters.formatCurrency(cart.subtotalPtr) : 'Cart',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cart.itemCount > 0 ? AppTheme.primary : AppTheme.slate800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18),
            tooltip: 'Exit Order Desk',
            onPressed: auth.logout,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Retailer Route Banner on Mobile
          if (!isDesktop && widget.retailer.route.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppTheme.primarySurface,
              child: Row(
                children: [
                  const Icon(Icons.alt_route_rounded, size: 14, color: AppTheme.primaryDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Route: ${widget.retailer.route} • Mobile: ${AppFormatters.formatIndianMobile(widget.retailer.mobile)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Isolated Search & Filter Bar Component
          CatalogFilterToolbar(
            searchController: _searchController,
            searchFocus: _searchFocus,
            isGridView: _isGridView,
            isDesktop: isDesktop,
            brands: desk.brands,
            selectedBrand: desk.selectedBrand,
            stockFilter: desk.stockFilter,
            onSearchChanged: desk.setSearchQuery,
            onClearSearch: () {
              _searchController.clear();
              desk.setSearchQuery('');
            },
            onToggleViewMode: () => setState(() => _isGridView = !_isGridView),
            onBrandSelected: desk.setSelectedBrand,
            onStockFilterSelected: desk.setStockFilter,
          ),

          // Count & Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.slate50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${desk.filteredProducts.length} of ${desk.totalCount} wholesale products',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.slate600,
                  ),
                ),
                Text(
                  '${desk.inStockCount} In Stock • ${desk.outOfStockCount} Out of Stock',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),

          // Main Product Catalog View
          Expanded(
            child: desk.filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 40, color: AppTheme.slate400),
                        const SizedBox(height: 8),
                        Text(
                          'No products matching "${desk.searchQuery}"',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slate700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            desk.resetFilters();
                          },
                          child: const Text('Reset Search & Filters'),
                        ),
                      ],
                    ),
                  )
                : _isGridView
                    ? CatalogCardGrid(
                        products: desk.filteredProducts,
                        enforceMoq: enforceMoq,
                      )
                    : isDesktop
                        ? CatalogDataTable(
                            products: desk.filteredProducts,
                            enforceMoq: enforceMoq,
                          )
                        : CatalogMobileList(
                            products: desk.filteredProducts,
                            enforceMoq: enforceMoq,
                          ),
          ),
        ],
      ),
    );
  }
}
