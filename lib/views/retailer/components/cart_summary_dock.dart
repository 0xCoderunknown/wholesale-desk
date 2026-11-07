import 'package:flutter/material.dart';
import '../../../config/formatters.dart';
import '../../../config/theme.dart';
import '../../../models/retailer.dart';
import '../../../state/cart_provider.dart';

/// Sticky right-hand order valuation summary and WhatsApp dispatch dock for desktop/tablet.
class CartSummaryDock extends StatelessWidget {
  final Retailer retailer;
  final CartProvider cart;
  final TextEditingController notesController;
  final bool isSending;
  final VoidCallback onSendOrder;

  const CartSummaryDock({
    super.key,
    required this.retailer,
    required this.cart,
    required this.notesController,
    required this.isSending,
    required this.onSendOrder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Retailer Credentials Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, size: 20, color: AppTheme.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        retailer.storeName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Route: ${retailer.route} • ${AppFormatters.formatIndianMobile(retailer.mobile)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.slate600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'Order Valuation Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate800),
          ),
          const SizedBox(height: 12),

          // Items & Packaging Breakdown
          _summaryRow('Billed Items:', '${cart.itemCount} items (${cart.totalUnits} units)'),
          const SizedBox(height: 6),
          _summaryRow(
            'Packaging Estimate:',
            '${cart.totalBoxes} Cartons + ${cart.totalLooseUnits} Loose',
            valueColor: const Color(0xFF1D4ED8),
            bold: true,
          ),
          const SizedBox(height: 6),
          _summaryRow('Gross MRP Value:', AppFormatters.formatCurrency(cart.totalMrp)),
          if (cart.totalEarnedFreeUnits > 0) ...[
            const SizedBox(height: 6),
            _summaryRow(
              'Bonus Free Goods:',
              '+${cart.totalEarnedFreeUnits} units FREE',
              valueColor: const Color(0xFF166534),
              bold: true,
            ),
          ],
          if (cart.totalSavings > 0) ...[
            const SizedBox(height: 6),
            _summaryRow(
              'Gross Retailer Margin:',
              '+ ${AppFormatters.formatCurrency(cart.totalSavings)}',
              valueColor: const Color(0xFF15803D),
              bold: true,
            ),
          ],

          const Divider(height: 24),

          // Grand Total (PTR)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Grand Total (PTR):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.formatCurrency(cart.subtotalPtr),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Order Remarks / Delivery Notes Input Field
          const Text(
            'Delivery Instructions / Remarks (Optional):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: notesController,
            maxLines: 2,
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'e.g., Deliver before 11 AM, pack in separate bags...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
              filled: true,
              fillColor: AppTheme.slate50,
              contentPadding: const EdgeInsets.all(10),
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

          const SizedBox(height: 20),

          // WhatsApp Checkout CTA
          ElevatedButton.icon(
            onPressed: isSending ? null : onSendOrder,
            icon: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              isSending ? 'Launching WhatsApp...' : 'Send Order on WhatsApp',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.whatsappGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Compiles itemized B2B order string directly to WhatsApp',
              style: TextStyle(fontSize: 10.5, color: AppTheme.slate500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppTheme.slate800,
          ),
        ),
      ],
    );
  }
}

