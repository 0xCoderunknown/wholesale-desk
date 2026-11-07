import 'package:flutter/material.dart';
import '../../config/formatters.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/scheme_helper.dart';

/// Shikhar-style collapsible scheme accordion component.
/// Shows single-line summary with "Get up to X% Margin" when collapsed,
/// and itemized breakdown with 1-tap apply trigger when expanded.
class SchemeCollapsibleAccordion extends StatefulWidget {
  final Product product;
  final bool inStock;
  final bool isAlreadyActive;
  final VoidCallback? onApplyScheme;

  const SchemeCollapsibleAccordion({
    super.key,
    required this.product,
    required this.inStock,
    this.isAlreadyActive = false,
    this.onApplyScheme,
  });

  @override
  State<SchemeCollapsibleAccordion> createState() => _SchemeCollapsibleAccordionState();
}

class _SchemeCollapsibleAccordionState extends State<SchemeCollapsibleAccordion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.product.scheme.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final p = widget.product;
    final details = SchemeHelper.getMaxSchemeDetails(
      scheme: p.scheme,
      ptr: p.ptr,
      mrp: p.mrp,
    );

    final hasBoost = details.maxMargin > p.marginPercent;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8), // Amber 50
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFDE047), // Amber 300
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collapsed Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  const Text('🏷️ ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      hasBoost
                          ? 'Scheme: ${p.scheme} (Get up to ${details.maxMargin.toStringAsFixed(1)}% Margin)'
                          : 'Scheme: ${p.scheme}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E), // Amber 800
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: const Color(0xFF92400E),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Breakdown
          if (_isExpanded) ...[
            Container(
              height: 1,
              color: const Color(0xFFFEF08A), // Amber 200
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (details.breakdownCopy.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: Color(0xFF15803D)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            details.breakdownCopy,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          size: 14, color: Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Text(
                        'Effective PTR: ${AppFormatters.formatCurrency(details.effPtr)}/unit',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  if (widget.inStock && details.threshold > 0 && widget.onApplyScheme != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: widget.onApplyScheme,
                      icon: const Icon(Icons.bolt_rounded, size: 14),
                      label: Text(
                        widget.isAlreadyActive
                            ? 'Add Another Slab (+${details.threshold} Units)'
                            : '⚡ Apply Scheme (+${details.threshold} Units)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size.fromHeight(32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
