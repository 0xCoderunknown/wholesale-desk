import 'package:flutter/material.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/retailer.dart';
import '../../../state/cart_provider.dart';

/// Streamlined order valuation summary and WhatsApp dispatch dock.
/// Focuses strictly on Total Items, Total Payable (PTR), and 1-line delivery notes.
class CartSummaryDock extends StatelessWidget {
  final Retailer retailer;
  final CartProvider cart;
  final TextEditingController notesController;
  final bool isSending;
  final VoidCallback onSendOrder;
  final VoidCallback? onCopyOrder;
  final bool showCheckoutButton;

  const CartSummaryDock({
    super.key,
    required this.retailer,
    required this.cart,
    required this.notesController,
    required this.isSending,
    required this.onSendOrder,
    this.onCopyOrder,
    this.showCheckoutButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final freeUnits = cart.totalEarnedFreeUnits;
    final itemsCountText = freeUnits > 0
        ? '${cart.itemCount} (${cart.totalUnits} billed + $freeUnits free)'
        : '${cart.itemCount} (${cart.totalUnits} billed)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Order Valuation Summary',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.slate900),
          ),
          const SizedBox(height: 14),

          // Total Items
          Row(
            children: [
              const Expanded(
                child: Text('Total Items:', style: TextStyle(fontSize: 13, color: AppTheme.slate600)),
              ),
              const SizedBox(width: 8),
              Text(
                itemsCountText,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate800),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Divider(height: 1),
          const SizedBox(height: 12),

          // Total Payable (PTR): large font size 22px, bold emerald green
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Payable (PTR):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.formatCurrency(cart.subtotalPtr),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669), // Bold emerald green
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Delivery remarks textarea (2-3 lines height)
          TextField(
            controller: notesController,
            minLines: 2,
            maxLines: 3,
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'Delivery notes (e.g., Send in afternoon van, billing remarks)...',
              hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.slate400),
              filled: true,
              fillColor: AppTheme.slate50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

          if (showCheckoutButton) ...[
            const SizedBox(height: 14),

            // Action Row: [ 📋 Copy ] + [ 🚀 Send Order on WhatsApp ]
            Row(
              children: [
                if (onCopyOrder != null) ...[
                  OutlinedButton.icon(
                    onPressed: onCopyOrder,
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text('Copy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.slate700,
                      side: const BorderSide(color: AppTheme.slate300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSending ? null : onSendOrder,
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('🚀', style: TextStyle(fontSize: 15)),
                    label: Text(
                      isSending ? 'Launching WhatsApp...' : 'Send Order on WhatsApp',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.whatsappGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Itemized order string compiles directly to WhatsApp chat',
                style: TextStyle(fontSize: 10.5, color: AppTheme.slate500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
