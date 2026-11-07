import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../models/retailer.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/desk_provider.dart';
import '../widgets/high_density_badge.dart';
import '../widgets/stock_toggle_pill.dart';
import 'cart_drawer.dart';

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

  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

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
    final cart = context.watch<CartProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 850;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.slate100,
      endDrawer: isDesktop ? CartDrawer(retailer: widget.retailer) : null,
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

          // Cart Button with Counter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => _openCartDrawer(context),
              icon: Badge(
                label: Text('${cart.itemCount}'),
                isLabelVisible: cart.itemCount > 0,
                backgroundColor: AppTheme.outOfStockRed,
                child: const Icon(Icons.shopping_cart_outlined, size: 17),
              ),
              label: Text(
                cart.subtotalPtr > 0 ? _currency.format(cart.subtotalPtr) : 'Cart',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cart.itemCount > 0 ? AppTheme.primary : AppTheme.slate800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
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
                      'Route: ${widget.retailer.route} • Mobile: ${widget.retailer.mobile}',
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

          // Instant Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.slate200)),
            ),
            child: Row(
              children: [
                // In-memory instant client-side search input
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: desk.setSearchQuery,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.slate500),
                      hintText: 'Search products by name, brand, or scheme (0ms latency)...',
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                desk.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Brand Selector Filter
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
                        value: desk.selectedBrand,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate800,
                        ),
                        items: desk.brands.map((b) {
                          return DropdownMenuItem(value: b, child: Text(b));
                        }).toList(),
                        onChanged: (b) {
                          if (b != null) desk.setSelectedBrand(b);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Stock Toggle Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.slate300),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StockFilterType>(
                      value: desk.stockFilter,
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate800,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: StockFilterType.all,
                          child: Text('All Stock'),
                        ),
                        DropdownMenuItem(
                          value: StockFilterType.inStock,
                          child: Text('In Stock Only'),
                        ),
                        DropdownMenuItem(
                          value: StockFilterType.outOfStock,
                          child: Text('Out of Stock Only'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) desk.setStockFilter(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
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

          // Main Product Catalog List / Table
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
                : isDesktop
                    ? _buildDesktopTable(desk.filteredProducts, cart)
                    : _buildMobileList(desk.filteredProducts, cart),
          ),

          // Bottom Mobile Sticky Cart Bar
          if (!isDesktop && cart.itemCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.slate900,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${cart.itemCount} Items (${cart.totalUnits} Units)',
                        style: const TextStyle(
                          color: AppTheme.slate300,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _currency.format(cart.subtotalPtr),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _openCartDrawer(context),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                    label: const Text('Review Cart & Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Desktop High-Density Table
  Widget _buildDesktopTable(List<Product> products, CartProvider cart) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 900),
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 52,
              horizontalMargin: 16,
              columnSpacing: 18,
              headingRowColor: WidgetStateProperty.all(AppTheme.slate100),
              columns: const [
                DataColumn(
                  label: Text(
                    'PRODUCT / BRAND',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'SCHEME',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'MOQ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'MRP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'PTR (RATE)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'MARGIN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'STATUS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ACTION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                  ),
                ),
              ],
              rows: products.map((p) {
                final inCart = cart.isInCart(p.id);
                final qty = cart.getQuantity(p.id);

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (inCart) return AppTheme.primarySurface.withValues(alpha: 0.4);
                    return null;
                  }),
                  cells: [
                    // Product & Brand (NO images rendered for zero-bloat)
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.slate900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              p.brand,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Scheme
                    DataCell(
                      SchemeBadge(scheme: p.scheme),
                    ),

                    // MOQ
                    DataCell(
                      MoqBadge(moq: p.moq),
                    ),

                    // MRP
                    DataCell(
                      Text(
                        _currency.format(p.mrp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),

                    // PTR
                    DataCell(
                      Text(
                        _currency.format(p.ptr),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),

                    // Margin %
                    DataCell(
                      Text(
                        '+${p.marginPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),

                    // Stock Pill (read-only for Retailer)
                    DataCell(
                      StockTogglePill(
                        inStock: p.inStock,
                        enabled: false,
                        compact: true,
                      ),
                    ),

                    // Cart Action / Stepper
                    DataCell(
                      p.inStock
                          ? inCart
                              ? _buildDesktopStepper(p, qty, cart)
                              : ElevatedButton(
                                  onPressed: () => cart.addItem(p),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text('Add (MOQ ${p.moq})'),
                                )
                          : const Text(
                              'Out of Stock',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.slate400,
                              ),
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

  Widget _buildDesktopStepper(Product p, int qty, CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primary, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => cart.decrement(p.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                qty <= p.moq ? Icons.delete_outline_rounded : Icons.remove_rounded,
                size: 14,
                color: qty <= p.moq ? AppTheme.outOfStockRed : AppTheme.slate700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$qty',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.slate900,
              ),
            ),
          ),
          InkWell(
            onTap: () => cart.increment(p.id),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.add_rounded, size: 14, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile High-Density POS Cards
  Widget _buildMobileList(List<Product> products, CartProvider cart) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = products[index];
        final inCart = cart.isInCart(p.id);
        final qty = cart.getQuantity(p.id);

        return Card(
          color: inCart ? AppTheme.primarySurface.withValues(alpha: 0.5) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: inCart ? AppTheme.primary : AppTheme.slate200,
              width: inCart ? 1.5 : 1,
            ),
          ),
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.brand,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StockTogglePill(
                      inStock: p.inStock,
                      enabled: false,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scheme & MOQ Badges
                Row(
                  children: [
                    if (p.scheme.trim().isNotEmpty) ...[
                      SchemeBadge(scheme: p.scheme),
                      const SizedBox(width: 6),
                    ],
                    MoqBadge(moq: p.moq),
                  ],
                ),
                const SizedBox(height: 10),

                // Rates & Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _currency.format(p.ptr),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currency.format(p.mrp),
                              style: const TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.slate400,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Retailer Margin: +${p.marginPercent.toStringAsFixed(1)}% (${_currency.format(p.margin)}/u)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),

                    // Add / Stepper
                    if (p.inStock)
                      inCart
                          ? _buildDesktopStepper(p, qty, cart)
                          : ElevatedButton(
                              onPressed: () => cart.addItem(p),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: Text('Add (MOQ ${p.moq})'),
                            )
                    else
                      const Text(
                        'Out of Stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate400,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
