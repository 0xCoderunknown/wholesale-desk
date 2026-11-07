import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/retailer.dart';
import '../../services/whatsapp_service.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../widgets/high_density_badge.dart';

class CartDrawer extends StatefulWidget {
  final Retailer retailer;

  const CartDrawer({super.key, required this.retailer});

  @override
  State<CartDrawer> createState() => _CartDrawerState();
}

class _CartDrawerState extends State<CartDrawer> {
  bool _isSending = false;
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Container(
      width: 440,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppTheme.slate200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppTheme.slate900,
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Wholesale Order Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (cart.items.isNotEmpty)
                  TextButton.icon(
                    onPressed: cart.clear,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppTheme.slate400),
                    label: const Text(
                      'Clear',
                      style: TextStyle(color: AppTheme.slate400, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Close Cart',
                ),
              ],
            ),
          ),

          // Retailer Info Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppTheme.slate100,
            child: Row(
              children: [
                const Icon(Icons.store_rounded, size: 16, color: AppTheme.slate700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.retailer.storeName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Route: ${widget.retailer.route} • ${widget.retailer.mobile}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 48,
                          color: AppTheme.slate300,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.slate600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add products from the catalog to build your order.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.slate400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final p = item.product;

                      return Column(
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
                                    Row(
                                      children: [
                                        Text(
                                          p.brand,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.slate500,
                                          ),
                                        ),
                                        if (item.hasScheme) ...[
                                          const SizedBox(width: 6),
                                          SchemeBadge(scheme: p.scheme),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Line Total
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currency.format(item.lineTotalPtr),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  Text(
                                    'MRP: ${_currency.format(item.lineTotalMrp)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                      color: AppTheme.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Rate info & Stepper
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PTR: ${_currency.format(p.ptr)} / unit (MOQ: ${p.moq})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.slate600,
                                ),
                              ),
                              // Compact Stepper
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.slate300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildStepButton(
                                      icon: item.quantity <= p.moq
                                          ? Icons.delete_outline_rounded
                                          : Icons.remove_rounded,
                                      color: item.quantity <= p.moq
                                          ? AppTheme.outOfStockRed
                                          : AppTheme.slate700,
                                      onTap: () => cart.decrement(p.id),
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 36),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.slate900,
                                        ),
                                      ),
                                    ),
                                    _buildStepButton(
                                      icon: Icons.add_rounded,
                                      color: AppTheme.primary,
                                      onTap: () => cart.increment(p.id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Drawer Summary Footer
          if (cart.items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.slate50,
                border: Border(top: BorderSide(color: AppTheme.slate200)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Items: ${cart.itemCount} (${cart.totalUnits} units)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate600,
                        ),
                      ),
                      Text(
                        'Gross MRP: ${_currency.format(cart.totalMrp)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (cart.totalSavings > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Retailer Margin:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          '+ ${_currency.format(cart.totalSavings)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Total (PTR):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                      ),
                      Text(
                        _currency.format(cart.subtotalPtr),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // WhatsApp Checkout Button
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : () => _handleWhatsAppCheckout(context),
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'Place Order on WhatsApp',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.whatsappGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
