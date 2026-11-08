import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/breakpoints.dart';
import '../../config/formatters.dart';
import '../../config/theme.dart';
import '../../models/retailer.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/desk_provider.dart';
import 'retailer_cart_screen.dart';
import 'components/catalog_card_grid.dart';
import 'components/catalog_data_table.dart';
import 'components/catalog_filter_toolbar.dart';

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

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Exit Order Desk?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to exit? Your cart items will remain saved on this device.',
          style: TextStyle(fontSize: 13, color: AppTheme.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slate600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.outOfStockRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      auth.logout();
    }
  }

  void _openCartDesk(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RetailerCartScreen(retailer: widget.retailer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final desk = context.watch<DeskProvider>();
    final isMobile = AppBreakpoints.isMobile(context);
    final isDesktop = AppBreakpoints.isDesktop(context);
    final hasMultiColumnCatalog = !isMobile;
    final enforceMoq = auth.settings.enforceMoq;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.slate100,
      floatingActionButton: !isMobile
          ? null
          : Consumer<CartProvider>(
              builder: (context, cart, _) {
                return FloatingActionButton.extended(
                  onPressed: () => _openCartDesk(context),
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
        title: isDesktop
            ? Row(
                children: [
                  // 1. Distributor Name Pill (Height 36)
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.slate800,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.slate700),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.primaryLight),
                        const SizedBox(width: 8),
                        Text(
                          auth.settings.storeName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Retailer Name Pill (Height 36)
                  Flexible(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.slate800,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.slate700),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 15, color: AppTheme.primaryLight),
                          const SizedBox(width: 6),
                          const Text(
                            'Retailer: ',
                            style: TextStyle(fontSize: 12, color: AppTheme.slate400),
                          ),
                          Flexible(
                            child: Text(
                              widget.retailer.storeName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Row(
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
                              'Verified: ',
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
                            if (isMobile && widget.retailer.route.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '• ${widget.retailer.route}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.slate300,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          // 3. Route Badge Pill on tablet/desktop (Height 36)
          if (!isMobile && widget.retailer.route.isNotEmpty) ...[
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.slate800,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.slate700),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.slate400),
                  const SizedBox(width: 5),
                  Text(
                    widget.retailer.route,
                    style: const TextStyle(fontSize: 12, color: AppTheme.slate200, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 4. Cart Action (Tablet/Desktop only; Mobile uses FloatingActionButton exclusively)
          if (!isMobile) ...[
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                return SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCartDesk(context),
                    icon: Badge(
                      label: Text('${cart.itemCount}'),
                      isLabelVisible: cart.itemCount > 0,
                      backgroundColor: AppTheme.outOfStockRed,
                      child: const Icon(Icons.shopping_cart_outlined, size: 16),
                    ),
                    label: Text(
                      cart.subtotalPtr > 0 ? AppFormatters.formatCurrency(cart.subtotalPtr) : 'Cart',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cart.itemCount > 0 ? AppTheme.primary : AppTheme.slate800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: cart.itemCount > 0 ? AppTheme.primary : AppTheme.slate700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],

          // 5. Logout / Exit Button (36px on tablet/desktop, icon on mobile, both guarded by _confirmLogout)
          if (!isMobile)
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, auth),
                icon: const Icon(Icons.logout_rounded, size: 15, color: AppTheme.slate300),
                label: const Text(
                  'Exit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate200),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.slate800,
                  side: const BorderSide(color: AppTheme.slate700),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout_rounded, size: 19, color: AppTheme.slate300),
              tooltip: 'Exit Order Desk',
              onPressed: () => _confirmLogout(context, auth),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Isolated Search & Filter Bar Component
          CatalogFilterToolbar(
            searchController: _searchController,
            searchFocus: _searchFocus,
            isGridView: _isGridView,
            isDesktop: hasMultiColumnCatalog,
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
                Expanded(
                  child: Text(
                    isMobile
                        ? '${desk.filteredProducts.length} products'
                        : 'Showing ${desk.filteredProducts.length} of ${desk.totalCount} wholesale products',
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
                  isMobile
                      ? '${desk.inStockCount} In Stock • ${desk.outOfStockCount} Out'
                      : '${desk.inStockCount} In Stock • ${desk.outOfStockCount} Out of Stock',
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
                : (!hasMultiColumnCatalog || _isGridView)
                    ? CatalogCardGrid(
                        products: desk.filteredProducts,
                        enforceMoq: enforceMoq,
                      )
                    : CatalogDataTable(
                        products: desk.filteredProducts,
                        enforceMoq: enforceMoq,
                      ),
          ),
        ],
      ),
    );
  }
}
