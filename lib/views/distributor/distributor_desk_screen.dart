import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/formatters.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/repository_manager.dart';
import '../../state/auth_provider.dart';
import '../../state/desk_provider.dart';
import '../widgets/high_density_badge.dart';
import '../widgets/stock_toggle_pill.dart';
import 'box_breakdown_dialog.dart';
import 'product_edit_dialog.dart';
import 'retailer_management_view.dart';
import 'store_settings_dialog.dart';

class DistributorDeskScreen extends StatefulWidget {
  const DistributorDeskScreen({super.key});

  @override
  State<DistributorDeskScreen> createState() => _DistributorDeskScreenState();
}

class _DistributorDeskScreenState extends State<DistributorDeskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _openProductDialog([Product? product]) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => ProductEditDialog(product: product),
    );
    if (result != null && mounted) {
      await context.read<DeskProvider>().saveProduct(result);
    }
  }

  void _openStoreSettings(BuildContext context) {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (_) => StoreSettingsDialog(settings: auth.settings),
    );
  }

  void _openBoxCalculator(BuildContext context, [Product? product]) {
    final desk = context.read<DeskProvider>();
    BoxBreakdownDialog.show(
      context,
      products: desk.products,
      initialProduct: product,
    );
  }

  Future<void> _resetDemoCatalog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Reset Demo Catalog?'),
          ],
        ),
        content: const Text(
          'This will re-seed the standard FMCG demo catalog (10 wholesale items) and 3 sample retailer accounts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Demo Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await RepositoryManager.instance.seedInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Demo wholesale catalog & retailers restored successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Logout Desk?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to exit the Distributor Desk?',
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final desk = context.watch<DeskProvider>();
    final isAdmin = auth.isAdmin;
    final isStaff = auth.isStaff;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: AppTheme.slate100,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isAdmin ? AppTheme.primary : const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isAdmin ? Icons.admin_panel_settings_rounded : Icons.badge_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          auth.settings.storeName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: auth.settings.isWooCommerce ? const Color(0xFF7C3AED) : AppTheme.slate700,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          auth.settings.isWooCommerce ? 'WOOCOMMERCE REST' : 'FIREBASE',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppTheme.primary : const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          isAdmin ? 'ADMIN DESK (MASTER)' : 'STAFF COUNTER (RESTRICTED)',
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isStaff && isDesktop)
                        const Text(
                          '• Stock Toggle Only',
                          style: TextStyle(fontSize: 10, color: AppTheme.slate400),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Quick Stats Pill
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.slate800,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.slate700),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${desk.totalCount} Products',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate200),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 12, color: AppTheme.slate600),
                    const SizedBox(width: 8),
                    Text(
                      '${desk.inStockCount} In Stock',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),

          // Dispatch Box Breakdown Calculator (Staff & Admin)
          IconButton(
            icon: const Icon(Icons.calculate_outlined, size: 20, color: Colors.white),
            tooltip: 'Dispatch Box Breakdown Calculator',
            onPressed: () => _openBoxCalculator(context),
          ),

          // Admin Actions
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFF59E0B)),
              tooltip: 'Reset Demo Catalog (10 Products & 3 Stores)',
              onPressed: _resetDemoCatalog,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              tooltip: 'Store & PIN Settings',
              onPressed: () => _openStoreSettings(context),
            ),
          ],

          // Logout Action
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Logout Desk',
            onPressed: () => _confirmLogout(context, auth),
          ),
          const SizedBox(width: 10),
        ],
        // If Admin, show Tabs for Catalog vs Retailer PINs. Staff ONLY sees Catalog.
        bottom: isAdmin
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryLight,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.slate400,
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Catalog & Stock Desk', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_alt_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Retailer PIN Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: isAdmin
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogDesk(desk, isAdmin, isDesktop),
                const RetailerManagementView(),
              ],
            )
          : _buildCatalogDesk(desk, false, isDesktop),
    );
  }

  Widget _buildCatalogDesk(DeskProvider desk, bool isAdmin, bool isDesktop) {
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
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: desk.setSearchQuery,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.slate500),
                      hintText: 'Counter search: product name, brand, or scheme...',
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
              ),
              const SizedBox(width: 10),

              // Brand Selector
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
              if (isAdmin) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => _openProductDialog(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  onTap: () => _openBoxCalculator(context),
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

        // Catalog Table / Cards
        Expanded(
          child: desk.filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.slate400),
                      const SizedBox(height: 8),
                      Text(
                        'No products match "${desk.searchQuery}"',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          desk.resetFilters();
                        },
                        child: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                )
              : isDesktop
                  ? _buildDistributorDesktopTable(desk, isAdmin)
                  : _buildDistributorMobileList(desk, isAdmin),
        ),
      ],
    );
  }

  Widget _buildDistributorDesktopTable(DeskProvider desk, bool isAdmin) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: isAdmin ? 1020 : 680),
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              horizontalMargin: 16,
              columnSpacing: 18,
              headingRowColor: WidgetStateProperty.all(AppTheme.slate100),
              columns: [
                const DataColumn(
                  label: Text('PRODUCT / BRAND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                if (isAdmin) ...[
                  const DataColumn(
                    label: Text('STOCK STATUS (CLICK TO TOGGLE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const DataColumn(
                    label: Text('SCHEME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const DataColumn(
                    label: Text('MOQ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const DataColumn(
                    label: Text('BOX PACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const DataColumn(
                    label: Text('MRP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const DataColumn(
                    label: Text('PTR (RATE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const DataColumn(
                    label: Text('MARGIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const DataColumn(
                    label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ] else ...[
                  // Staff Warehouse Columns: Strict Rate Privacy & Physical Box Ergonomics
                  const DataColumn(
                    label: Text('BOX / CASE PACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const DataColumn(
                    label: Text('STOCK AVAILABILITY (CLICK TO TOGGLE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
              rows: desk.filteredProducts.map((p) {
                if (!isAdmin) {
                  // Staff Godown Row: Rate-Shielded Product Details, High-Contrast Box Pack & Stock Toggle
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
                          onTap: () => _openBoxCalculator(context, p),
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
                }

                // Admin Row (Full access with pricing, schemes, and management actions)
                return DataRow(
                  cells: [
                    // Product & Brand (Zero bloat, no image widget)
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

                    // Box Pack / Carton (Admin clickable to open calculator)
                    DataCell(
                      p.hasCartonPack
                          ? InkWell(
                              onTap: () => _openBoxCalculator(context, p),
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

                    // Actions (Admin only: In-place edit or delete)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 17, color: AppTheme.slate700),
                            tooltip: 'Edit Rates & Scheme',
                            onPressed: () => _openProductDialog(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.outOfStockRed),
                            tooltip: 'Delete Product',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Product?'),
                                  content: Text('Delete "${p.name}" from wholesale catalog?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.outOfStockRed),
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await desk.deleteProduct(p.id);
                              }
                            },
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

  Widget _buildDistributorMobileList(DeskProvider desk, bool isAdmin) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: desk.filteredProducts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = desk.filteredProducts[index];

        if (!isAdmin) {
          // Staff Warehouse Mobile Card: Rate Shielded & Full-Width Thumb Target
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: p.inStock ? AppTheme.slate200 : AppTheme.outOfStockRed.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
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

                  // Row 2: Prominent Box Pack Badge (Tap to calculate breakdown)
                  InkWell(
                    onTap: () => _openBoxCalculator(context, p),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  const SizedBox(height: 12),

                  // Row 3: Comfortable Full-Width Stock Toggle Target for Walking Godown Aisles
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: StockTogglePill(
                      inStock: p.inStock,
                      enabled: true,
                      onToggle: () => desk.toggleStock(p.id, !p.inStock),
                    ),
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

                Row(
                  children: [
                    if (p.scheme.trim().isNotEmpty) ...[
                      SchemeBadge(scheme: p.scheme),
                      const SizedBox(width: 6),
                    ],
                    MoqBadge(moq: p.moq),
                    if (p.hasCartonPack) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _openBoxCalculator(context, p),
                        borderRadius: BorderRadius.circular(4),
                        child: BoxPackBadge(cartonPack: p.cartonPack),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PTR: ${AppFormatters.formatCurrency(p.ptr)} (MRP: ${AppFormatters.formatCurrency(p.mrp)})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          onPressed: () => _openProductDialog(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.outOfStockRed),
                          onPressed: () => desk.deleteProduct(p.id),
                        ),
                      ],
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
