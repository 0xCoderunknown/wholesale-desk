import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../models/retailer.dart';
import '../../services/scheme_helper.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/desk_provider.dart';
import '../widgets/high_density_badge.dart';
import '../widgets/product_avatar.dart';
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

  bool _isGridView = false;

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
    final enforceMoq = auth.settings.enforceMoq;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.slate100,
      endDrawer: isDesktop ? CartDrawer(retailer: widget.retailer) : null,
      floatingActionButton: FloatingActionButton.extended(
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
              ? '${_currency.format(cart.subtotalPtr)} • Cart'
              : 'Cart',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
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
                const SizedBox(width: 8),

                // View Mode Toggle (Thumbnail Cards vs Table/List)
                Tooltip(
                  message: _isGridView ? 'Switch to List View' : 'Switch to Thumbnail Cards',
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    icon: Icon(
                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      size: 16,
                      color: AppTheme.slate700,
                    ),
                    label: Text(
                      _isGridView ? 'List' : 'Cards',
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

          // Main Product Catalog (Grid, Table, or List)
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
                    ? _buildGridView(desk.filteredProducts, cart, enforceMoq)
                    : isDesktop
                        ? _buildDesktopTable(desk.filteredProducts, cart, enforceMoq)
                        : _buildMobileList(desk.filteredProducts, cart, enforceMoq),
          ),
        ],
      ),
    );
  }

  // Thumbnail Card Grid View (with Monogram Letters, Nudges, Scheme Auto-Fill & Direct Delete)
  Widget _buildGridView(List<Product> products, CartProvider cart, bool enforceMoq) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 280,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final inCart = cart.isInCart(p.id);
        final qty = cart.getQuantity(p.id);
        final schemeThreshold = SchemeHelper.parseThreshold(p.scheme);
        final nudge = SchemeHelper.calculateNudge(
          scheme: p.scheme,
          currentQuantity: inCart ? qty : 0,
          ptr: p.ptr,
          mrp: p.mrp,
        );

        return Card(
          elevation: inCart ? 2 : 0,
          color: inCart ? AppTheme.primarySurface.withValues(alpha: 0.45) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
                // Header with Monogram Avatar & Stock Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductAvatar(
                      name: p.name,
                      brand: p.brand,
                      size: 42,
                      fontSize: 18,
                    ),
                    const SizedBox(width: 10),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.brand,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.slate500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    StockTogglePill(
                      inStock: p.inStock,
                      enabled: false,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Badges row: Scheme, 1-Tap Auto-Fill, MOQ & Box Pack
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (p.scheme.trim().isNotEmpty) ...[
                      SchemeBadge(scheme: p.scheme),
                      if (schemeThreshold > 0 && p.inStock)
                        SchemeApplyPill(
                          threshold: schemeThreshold,
                          isAlreadyActive: inCart && qty >= schemeThreshold,
                          onApply: () => cart.applyScheme(p, schemeThreshold, enforceMoq: enforceMoq),
                        ),
                    ],
                    MoqBadge(moq: p.moq),
                    if (p.hasCartonPack) BoxPackBadge(cartonPack: p.cartonPack),
                  ],
                ),

                // Upselling Nudge Prompt with Real-Time Distance Micro-Copy
                if (nudge.hasScheme && nudge.message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SchemeNudgePill(
                    message: nudge.message,
                    isQualified: nudge.isQualified,
                  ),
                ],

                const Spacer(),

                // Price and Dynamic Boosted Margin Row (MRP WITHOUT strikethrough)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currency.format(p.ptr),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        Text(
                          'MRP: ${_currency.format(p.mrp)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: MarginBoostBadge(
                        baseMargin: p.marginPercent,
                        effectiveMargin: nudge.effectiveMarginPercent,
                        effectivePtr: nudge.effectivePtr,
                        isBoosted: nudge.hasBoostedMargin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Prominent Add to Cart Button or Stepper with Direct ✕ Zero-Reset
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: p.inStock
                      ? inCart
                          ? _buildFullWidthStepper(p, qty, cart, enforceMoq)
                          : ElevatedButton.icon(
                              onPressed: () => cart.addItem(p, enforceMoq: enforceMoq),
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                              label: const Text(
                                'Add to Cart',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            )
                      : Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.slate100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.slate400,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Desktop High-Density Table with Direct Delete and Dynamic Margin Boost
  Widget _buildDesktopTable(List<Product> products, CartProvider cart, bool enforceMoq) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1080),
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              horizontalMargin: 16,
              columnSpacing: 16,
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
                    'SCHEME & 1-TAP APPLY',
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
                    'BOX PACK',
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
                final schemeThreshold = SchemeHelper.parseThreshold(p.scheme);
                final nudge = SchemeHelper.calculateNudge(
                  scheme: p.scheme,
                  currentQuantity: inCart ? qty : 0,
                  ptr: p.ptr,
                  mrp: p.mrp,
                );

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (inCart) return AppTheme.primarySurface.withValues(alpha: 0.4);
                    return null;
                  }),
                  cells: [
                    // Product & Brand with Letter Monogram Avatar (NO image overhead)
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Row(
                          children: [
                            ProductAvatar(
                              name: p.name,
                              brand: p.brand,
                              size: 34,
                              fontSize: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
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
                          ],
                        ),
                      ),
                    ),

                    // Scheme with 1-Tap Auto-Fill & Distance Nudge
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.scheme.trim().isNotEmpty) SchemeBadge(scheme: p.scheme),
                              if (schemeThreshold > 0 && p.inStock) ...[
                                const SizedBox(width: 4),
                                SchemeApplyPill(
                                  threshold: schemeThreshold,
                                  isAlreadyActive: inCart && qty >= schemeThreshold,
                                  onApply: () => cart.applyScheme(p, schemeThreshold, enforceMoq: enforceMoq),
                                ),
                              ],
                            ],
                          ),
                          if (nudge.hasScheme && nudge.message.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            SchemeNudgePill(
                              message: nudge.message,
                              isQualified: nudge.isQualified,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // MOQ
                    DataCell(
                      MoqBadge(moq: p.moq),
                    ),

                    // Box Pack
                    DataCell(
                      p.hasCartonPack
                          ? BoxPackBadge(cartonPack: p.cartonPack)
                          : const Text('-', style: TextStyle(color: AppTheme.slate400, fontSize: 12)),
                    ),

                    // MRP (Clean text, NO strikethrough)
                    DataCell(
                      Text(
                        _currency.format(p.mrp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate600,
                          fontWeight: FontWeight.w500,
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

                    // Margin % (with Boosted Scheme Indicator)
                    DataCell(
                      MarginBoostBadge(
                        baseMargin: p.marginPercent,
                        effectiveMargin: nudge.effectiveMarginPercent,
                        effectivePtr: nudge.effectivePtr,
                        isBoosted: nudge.hasBoostedMargin,
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

                    // Large Add to Cart Button or Stepper with Direct ✕ Zero-Reset
                    DataCell(
                      p.inStock
                          ? inCart
                              ? _buildDesktopStepper(p, qty, cart, enforceMoq)
                              : ElevatedButton.icon(
                                  onPressed: () => cart.addItem(p, enforceMoq: enforceMoq),
                                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                                  label: const Text('Add to Cart'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
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

  Widget _buildDesktopStepper(Product p, int qty, CartProvider cart, bool enforceMoq) {
    final minBound = (enforceMoq && p.moq > 0) ? p.moq : 1;

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
                onTap: () => cart.decrement(p.id, enforceMoq: enforceMoq),
                onLongPress: () => cart.removeItem(p.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(
                    qty <= minBound ? Icons.delete_outline_rounded : Icons.remove_rounded,
                    size: 15,
                    color: qty <= minBound ? AppTheme.outOfStockRed : AppTheme.slate700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$qty',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
              InkWell(
                onTap: () => cart.increment(p.id),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Icons.add_rounded, size: 15, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Direct 1-Tap Zero-Reset Button
        Tooltip(
          message: 'Zero out / Remove from cart',
          child: InkWell(
            onTap: () => cart.removeItem(p.id),
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

  Widget _buildFullWidthStepper(Product p, int qty, CartProvider cart, bool enforceMoq) {
    final minBound = (enforceMoq && p.moq > 0) ? p.moq : 1;

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
            onTap: () => cart.decrement(p.id, enforceMoq: enforceMoq),
            onLongPress: () => cart.removeItem(p.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Icon(
                qty <= minBound ? Icons.delete_outline_rounded : Icons.remove_rounded,
                size: 16,
                color: qty <= minBound ? AppTheme.outOfStockRed : AppTheme.slate700,
              ),
            ),
          ),
          Text(
            '$qty Units',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          InkWell(
            onTap: () => cart.increment(p.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
            ),
          ),
          // Direct 1-Tap Zero-Reset Close Target
          InkWell(
            onTap: () => cart.removeItem(p.id),
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

  // Mobile High-Density POS Cards with 1-Tap Auto-Fill & Direct Delete
  Widget _buildMobileList(List<Product> products, CartProvider cart, bool enforceMoq) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = products[index];
        final inCart = cart.isInCart(p.id);
        final qty = cart.getQuantity(p.id);
        final schemeThreshold = SchemeHelper.parseThreshold(p.scheme);
        final nudge = SchemeHelper.calculateNudge(
          scheme: p.scheme,
          currentQuantity: inCart ? qty : 0,
          ptr: p.ptr,
          mrp: p.mrp,
        );

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
                    ProductAvatar(
                      name: p.name,
                      brand: p.brand,
                      size: 38,
                      fontSize: 16,
                    ),
                    const SizedBox(width: 10),
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

                // Scheme, 1-Tap Auto-Fill, MOQ & Box Pack Badges
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (p.scheme.trim().isNotEmpty) ...[
                      SchemeBadge(scheme: p.scheme),
                      if (schemeThreshold > 0 && p.inStock)
                        SchemeApplyPill(
                          threshold: schemeThreshold,
                          isAlreadyActive: inCart && qty >= schemeThreshold,
                          onApply: () => cart.applyScheme(p, schemeThreshold, enforceMoq: enforceMoq),
                        ),
                    ],
                    MoqBadge(moq: p.moq),
                    if (p.hasCartonPack) BoxPackBadge(cartonPack: p.cartonPack),
                  ],
                ),

                // Upselling Nudge with Real-Time Distance Micro-Copy
                if (nudge.hasScheme && nudge.message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SchemeNudgePill(
                    message: nudge.message,
                    isQualified: nudge.isQualified,
                  ),
                ],

                const SizedBox(height: 10),

                // Rates & Action Row (with Boosted Margin & Direct Delete)
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
                              'MRP: ${_currency.format(p.mrp)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.slate500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        MarginBoostBadge(
                          baseMargin: p.marginPercent,
                          effectiveMargin: nudge.effectiveMarginPercent,
                          effectivePtr: nudge.effectivePtr,
                          isBoosted: nudge.hasBoostedMargin,
                        ),
                      ],
                    ),

                    // Add / Stepper with Direct ✕ Zero-Reset
                    if (p.inStock)
                      inCart
                          ? _buildDesktopStepper(p, qty, cart, enforceMoq)
                          : ElevatedButton.icon(
                              onPressed: () => cart.addItem(p, enforceMoq: enforceMoq),
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                              label: const Text('Add to Cart'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
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
