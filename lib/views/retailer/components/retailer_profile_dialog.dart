import 'package:material_ui/material_ui.dart';
import '../../../config/theme.dart';
import '../../../models/retailer.dart';
import '../../../state/auth_provider.dart';

/// Read-only Retailer Profile and Account Guardrail Modal.
/// Displays master ledger credentials governed strictly by Distributor ERP (Marg/Tally).
/// All fields are immutable to the retailer; includes safe session sign-out/switch store action.
class RetailerProfileDialog extends StatelessWidget {
  final Retailer retailer;
  final AuthProvider auth;

  const RetailerProfileDialog({
    super.key,
    required this.retailer,
    required this.auth,
  });

  static Future<void> show(BuildContext context, Retailer retailer, AuthProvider auth) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => RetailerProfileDialog(retailer: retailer, auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distPhone = auth.settings.whatsappPhone.trim().isNotEmpty
        ? auth.settings.whatsappPhone.trim()
        : 'your distributor desk';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Store Profile Title & Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 20, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Store Profile & Ledger',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.slate400),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Locked Status Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Amber 100
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFCD34D)), // Amber 300
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 14, color: Color(0xFFB45309)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '🔒 Managed by Distributor ERP',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309), // Amber 700
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Read-Only Credential Card (Strict Master Ledger Integrity)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Column(
                  children: [
                    _buildReadOnlyField(
                      label: 'Store Name',
                      value: retailer.storeName,
                      icon: Icons.business_rounded,
                    ),
                    const Divider(height: 16, color: AppTheme.slate200),
                    _buildReadOnlyField(
                      label: 'Party Code',
                      value: retailer.id.isNotEmpty
                          ? retailer.id
                          : (retailer.mobile.length >= 4
                              ? 'RET-${retailer.mobile.substring(retailer.mobile.length - 4)}'
                              : 'RET-0001'),
                      icon: Icons.qr_code_rounded,
                    ),
                    const Divider(height: 16, color: AppTheme.slate200),
                    _buildReadOnlyField(
                      label: 'Assigned Route',
                      value: retailer.route.isNotEmpty ? retailer.route : 'Main Market Route',
                      icon: Icons.route_rounded,
                    ),
                    const Divider(height: 16, color: AppTheme.slate200),
                    _buildReadOnlyField(
                      label: 'Registered Phone',
                      value: retailer.mobile,
                      icon: Icons.phone_android_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Help / Dispute Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.slate500),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'To update store address, route, or reset PIN, contact your distributor desk at $distPhone.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Session & Counter Handoff Controls: Sign Out / Switch Store
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  auth.logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.outOfStockRed),
                label: const Text(
                  'Sign Out / Switch Store',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.outOfStockRed,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFCA5A5)), // Red 300
                  backgroundColor: const Color(0xFFFEF2F2), // Red 50
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppTheme.slate400),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
