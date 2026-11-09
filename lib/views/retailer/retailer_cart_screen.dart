import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/formatters.dart';
import '../../config/theme.dart';
import '../../models/retailer.dart';
import '../../services/whatsapp_service.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import 'components/cart_invoice_table.dart';
import 'components/cart_mobile_card.dart';
import 'components/cart_scheme_maximizer.dart';
import 'components/cart_summary_dock.dart';
import 'components/retailer_profile_dialog.dart';

/// Streamlined Wholesale Order & Dispatch Desk.
/// Enforces minimal top navigation, single-line identity header,
/// high-density line items, and compressed valuation summary.
class RetailerCartScreen extends StatefulWidget {
  final Retailer retailer;

  const RetailerCartScreen({super.key, required this.retailer});

  @override
  State<RetailerCartScreen> createState() => _RetailerCartScreenState();
}

class _RetailerCartScreenState extends State<RetailerCartScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
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

    final bookedBy = auth.isSalesman
        ? (auth.activeSalesmanName?.isNotEmpty == true
            ? '${auth.activeSalesmanName} (Salesman)'
            : 'Salesman')
        : null;

    final success = await WhatsAppService.sendWholesaleOrder(
      targetPhone: auth.settings.whatsappPhone,
      storeName: auth.settings.storeName,
      retailer: widget.retailer,
      items: cart.items,
      totalPtr: cart.subtotalPtr,
      totalMrp: cart.totalMrp,
      orderNotes: _notesController.text.trim(),
      bookedBy: bookedBy,
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

  Future<void> _handleCopyOrderText(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (cart.items.isEmpty) return;

    final bookedBy = auth.isSalesman
        ? (auth.activeSalesmanName?.isNotEmpty == true
            ? '${auth.activeSalesmanName} (Salesman)'
            : 'Salesman')
        : null;

    final message = WhatsAppService.buildOrderMessage(
      storeName: auth.settings.storeName,
      retailer: widget.retailer,
      items: cart.items,
      totalPtr: cart.subtotalPtr,
      totalMrp: cart.totalMrp,
      orderNotes: _notesController.text.trim(),
      bookedBy: bookedBy,
    );

    await Clipboard.setData(ClipboardData(text: message));

    if (mounted) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Order text copied to clipboard!'),
          backgroundColor: AppTheme.slate800,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmClearCart(BuildContext context, CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Clear Cart?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;
    final enforceMoq = auth.settings.enforceMoq;

    final routePart = widget.retailer.route.isNotEmpty ? ' · ${widget.retailer.route}' : '';
    final identityText = 'Ordering for: ${widget.retailer.storeName}$routePart';

    return Scaffold(
      backgroundColor: AppTheme.slate100,
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 90,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ),
        title: Text(
          'Cart (${cart.itemCount})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _confirmClearCart(context, cart),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFFCA5A5)),
                label: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Single Identity Header (Tappable for Profile & Ledger details)
                InkWell(
                  onTap: () => RetailerProfileDialog.show(context, widget.retailer, auth),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    color: const Color(0xFFE2E8F0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: Text(
                          identityText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slate700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Cart Body
                Expanded(
                  child: isDesktop
                      ? _buildDesktopLayout(context, cart, enforceMoq)
                      : isTablet
                          ? _buildTabletLayout(context, cart, enforceMoq)
                          : _buildMobileLayout(context, cart, enforceMoq),
                ),
              ],
            ),
      bottomNavigationBar: (isMobile && cart.items.isNotEmpty)
          ? _buildMobileStickyBottomBar(context, cart)
          : null,
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
  // DESKTOP 2-COLUMN SPLIT (>= 1024px, max-width: 1240px, centered)
  // =========================================================================
  Widget _buildDesktopLayout(
    BuildContext context,
    CartProvider cart,
    bool enforceMoq,
  ) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CartSchemeMaximizer(cart: cart, enforceMoq: enforceMoq),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left (Items Table): flex: 1 (approx. 68% to 70% width)
                    Expanded(
                      child: SingleChildScrollView(
                        child: CartInvoiceTable(
                          items: cart.items,
                          cart: cart,
                          enforceMoq: enforceMoq,
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    // Right (Valuation Card): Fixed width 350px (approx. 30% to 32% width), pinned at top
                    SizedBox(
                      width: 350,
                      child: SingleChildScrollView(
                        child: CartSummaryDock(
                          retailer: widget.retailer,
                          cart: cart,
                          notesController: _notesController,
                          isSending: _isSending,
                          onSendOrder: () => _handleWhatsAppCheckout(context),
                          onCopyOrder: () => _handleCopyOrderText(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TABLET SINGLE-COLUMN STACK (768px - 1023px, max-width: 1240px, centered)
  // =========================================================================
  Widget _buildTabletLayout(
    BuildContext context,
    CartProvider cart,
    bool enforceMoq,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CartSchemeMaximizer(cart: cart, enforceMoq: enforceMoq),
              const SizedBox(height: 12),
              CartInvoiceTable(
                items: cart.items,
                cart: cart,
                enforceMoq: enforceMoq,
              ),
              const SizedBox(height: 16),
              CartSummaryDock(
                retailer: widget.retailer,
                cart: cart,
                notesController: _notesController,
                isSending: _isSending,
                onSendOrder: () => _handleWhatsAppCheckout(context),
                onCopyOrder: () => _handleCopyOrderText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // MOBILE ADAPTATION (< 768px)
  // =========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    CartProvider cart,
    bool enforceMoq,
  ) {
    return ListView(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 90),
      children: [
        CartSchemeMaximizer(cart: cart, enforceMoq: enforceMoq),
        const SizedBox(height: 8),
        for (final item in cart.items)
          CartMobileCard(
            item: item,
            cart: cart,
            enforceMoq: enforceMoq,
          ),
        const SizedBox(height: 12),
        CartSummaryDock(
          retailer: widget.retailer,
          cart: cart,
          notesController: _notesController,
          isSending: _isSending,
          onSendOrder: () => _handleWhatsAppCheckout(context),
          showCheckoutButton: false,
        ),
      ],
    );
  }

  // Sticky bottom action bar on mobile
  Widget _buildMobileStickyBottomBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.slate200)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Payable',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                ),
                Text(
                  AppFormatters.formatCurrency(cart.subtotalPtr),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                ),
              ],
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _handleCopyOrderText(context),
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text(
                'Copy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.slate700,
                side: const BorderSide(color: AppTheme.slate300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : () => _handleWhatsAppCheckout(context),
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('🚀', style: TextStyle(fontSize: 14)),
                label: Text(
                  _isSending ? 'Launching...' : 'Send on WhatsApp',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
    );
  }
}
