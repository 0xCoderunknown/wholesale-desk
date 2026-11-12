import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/repository_manager.dart';
import '../../state/auth_provider.dart';
import '../../state/desk_provider.dart';
import 'box_breakdown_dialog.dart';
import 'components/distributor_admin_table.dart';
import 'components/distributor_counter_bar.dart';
import 'components/distributor_mobile_card.dart';
import 'components/distributor_staff_table.dart';
import 'product_edit_dialog.dart';
import 'retailer_management_view.dart';
import 'store_settings_dialog.dart';

/// Distributor Operations Desk.
/// Supports high-speed counter catalog management for Admin (Master PIN),
/// and restricted Godown box-handling mode for Staff (zero margin visibility).
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ "${result.name}" updated successfully.'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  Future<void> _handleDeleteProduct(Product p) async {
    final desk = context.read<DeskProvider>();
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
        // Counter Fast Search, Filter & Summary Bar
        DistributorCounterBar(
          searchController: _searchController,
          searchFocus: _searchFocus,
          isAdmin: isAdmin,
          isDesktop: isDesktop,
          onAddProduct: isAdmin ? () => _openProductDialog() : null,
          onOpenBoxCalculator: () => _openBoxCalculator(context),
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
                  ? (isAdmin
                      ? DistributorAdminTable(
                          onEditProduct: _openProductDialog,
                          onDeleteProduct: _handleDeleteProduct,
                          onOpenBoxCalculator: (p) => _openBoxCalculator(context, p),
                        )
                      : DistributorStaffTable(
                          onOpenBoxCalculator: (p) => _openBoxCalculator(context, p),
                        ))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: desk.filteredProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = desk.filteredProducts[index];
                        return DistributorMobileCard(
                          product: p,
                          isAdmin: isAdmin,
                          onOpenBoxCalculator: (prod) => _openBoxCalculator(context, prod),
                          onEditProduct: isAdmin ? _openProductDialog : null,
                          onDeleteProduct: isAdmin ? _handleDeleteProduct : null,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
