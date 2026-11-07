import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/breakpoints.dart';
import '../../config/formatters.dart';
import '../../config/theme.dart';
import '../../models/cart_item.dart';
import '../../models/retailer.dart';
import '../../services/whatsapp_service.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import 'components/cart_invoice_table.dart';
import 'components/cart_mobile_card.dart';
import 'components/cart_scheme_maximizer.dart';
import 'components/cart_summary_dock.dart';

/// Full-screen Wholesale Order & Dispatch Desk.
/// Orchestrates desktop 2-panel proforma invoice review and mobile high-density dispatch flow.
class RetailerCartScreen extends StatefulWidget {
  final Retailer retailer;

  const RetailerCartScreen({super.key, required this.retailer});

  @override
  State<RetailerCartScreen> createState() => _RetailerCartScreenState();
}

class _RetailerCartScreenState extends State<RetailerCartScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleWhatsAppCheckout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (cart.items.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    final success = await WhatsAppService.sendWholesaleOrder(
      targetPhone: auth.settings.whatsappPhone,
      storeName: auth.settings.storeName,
      retailer: widget.retailer,
      items: cart.items,
      totalPtr: cart.subtotalPtr,
      totalMrp: cart.totalMrp,
      orderNotes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSending = false;
      });

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('WhatsApp opened with your itemized wholesale order!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Please ensure WhatsApp is installed or web is accessible.'),
            backgroundColor: AppTheme.outOfStockRed,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearCart(BuildContext context, CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Clear Wholesale Cart?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to remove all items from your order?',
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cart.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final isDesktop = AppBreakpoints.isDesktop(context);
    final isTablet = AppBreakpoints.isTablet(context);
    final enforceMoq = auth.settings.enforceMoq;

    // Filter cart items by in-cart search query
    final filteredItems = cart.items.where((it) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return it.product.name.toLowerCase().contains(q) ||
          it.product.brand.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.slate100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Back to Catalog',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      const Text(
                        'Wholesale Order Desk',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${cart.itemCount} items • ${cart.totalUnits}u',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.retailer.storeName} (${widget.retailer.route})',
                    style: const TextStyle(fontSize: 11, color: AppTheme.slate300),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearCart(context, cart),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppTheme.slate300),
              label: const Text(
                'Clear',
                style: TextStyle(color: AppTheme.slate300, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState(context)
          : isDesktop || isTablet
              ? _buildDesktopLayout(context, cart, filteredItems, enforceMoq, isTablet)
              : _buildMobileLayout(context, cart, filteredItems, enforceMoq),
    );
  }

  // =========================================================================
  // EMPTY STATE
  // =========================================================================
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.slate100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_shopping_cart_outlined,
                size: 48,
                color: AppTheme.slate400,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your wholesale cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore the catalog, apply volume schemes, and add items to build your wholesale order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.slate500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Product Catalog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // DESKTOP & TABLET 2-PANEL LAYOUT
  // =========================================================================
  Widget _buildDesktopLayout(
    BuildContext context,
    CartProvider cart,
    List<CartItem> items,
    bool enforceMoq,
    bool isTablet,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Panel: Search + Scheme Maximizer + Invoice Table
        Expanded(
          flex: isTablet ? 6 : 7,
          child: Column(
            children: [
              // Top Controls Bar (Search + Add More)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppTheme.slate200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search items in order...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppTheme.slate400),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.slate400),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.slate400),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppTheme.slate50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: AppTheme.slate300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                      label: const Text('Add More Products'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDark,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),

              // Real-time Scheme Maximizer Strip
              CartSchemeMaximizer(cart: cart, enforceMoq: enforceMoq),

              // Invoice Data Table
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No items match "$_searchQuery"',
                          style: const TextStyle(fontSize: 14, color: AppTheme.slate500),
                        ),
                      )
                    : CartInvoiceTable(
                        items: items,
                        cart: cart,
                        enforceMoq: enforceMoq,
                      ),
              ),
            ],
          ),
        ),

        // Right Panel: Sticky Bill Summary & WhatsApp Dispatch Dock
        Container(
          width: isTablet ? 320 : 380,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: AppTheme.slate200)),
          ),
          child: CartSummaryDock(
            retailer: widget.retailer,
            cart: cart,
            notesController: _notesController,
            isSending: _isSending,
            onSendOrder: () => _handleWhatsAppCheckout(context),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // MOBILE REVIEW FLOW (< 768px)
  // =========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    CartProvider cart,
    List<CartItem> items,
    bool enforceMoq,
  ) {
    return Column(
      children: [
        // Scheme Maximizer Alert Strip
        CartSchemeMaximizer(cart: cart, enforceMoq: enforceMoq),

        // Scrollable Items List + Notes
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              // In-Cart Search Bar
              SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search items in order...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                    prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.slate400),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.slate400),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppTheme.slate300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Modular Item Cards
              for (final item in items)
                CartMobileCard(
                  item: item,
                  cart: cart,
                  enforceMoq: enforceMoq,
                ),

              const SizedBox(height: 10),

              // Packaging & Notes Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Packaging: ${cart.totalBoxes} Cartons + ${cart.totalLooseUnits} Loose Units',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Delivery Remarks / Instructions (Optional):',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'e.g. Deliver before 11 AM, pack detergent in sacks...',
                        hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.slate400),
                        filled: true,
                        fillColor: AppTheme.slate50,
                        contentPadding: const EdgeInsets.all(8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppTheme.slate300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                label: const Text('Back to Catalog to Add More Items'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Sticky Bottom Dispatch Dock
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: ${cart.itemCount} items (${cart.totalUnits}u)',
                          style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cart.totalSavings > 0)
                          Text(
                            'Savings: +${AppFormatters.formatCurrency(cart.totalSavings)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatCurrency(cart.subtotalPtr),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : () => _handleWhatsAppCheckout(context),
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSending ? 'Launching WhatsApp...' : 'Send Order on WhatsApp',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.whatsappGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
