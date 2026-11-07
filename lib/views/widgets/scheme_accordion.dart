import 'package:flutter/material.dart';
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

    final isTiered = details.threshold > 0;

    // Requirement 3: Static info strip for continuous/percentage schemes (no expansion, no arrow)
    if (!isTiered) {
      final schemeLabel = p.scheme.trim().toLowerCase().contains('net rate')
          ? 'Net Rate auto-applied'
          : '${p.scheme.trim()} auto-applied';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFCE8), // Amber 50
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFFDE047), // Amber 300
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Text('🏷️ ', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Text(
                schemeLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final isActive = widget.isAlreadyActive;

    // Expandable accordion for tiered schemes (10+1, 12+1 Free, Buy 24 Get ₹100 Off)
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEFCE8), // Emerald 50 when active, else Amber 50
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFFDE047), // Emerald 300 vs Amber 300
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Tappable to expand/collapse)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Text(isActive ? '✓ ' : '🏷️ ', style: const TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      isActive
                          ? 'Scheme Active: ${p.scheme}'
                          : 'Scheme: ${p.scheme}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isActive ? const Color(0xFF065F46) : const Color(0xFF92400E),
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
                    color: isActive ? const Color(0xFF065F46) : const Color(0xFF92400E),
                  ),
                ],
              ),
            ),
          ),

          // Compact Accordion Drawer (tight 8px padding, combined single-line info)
          if (_isExpanded) ...[
            Container(
              height: 1,
              color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFEF08A),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Clean single line: Breakdown rule
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 13,
                        color: const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          details.breakdownCopy,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Action button: solid pressed emerald button if already qualified/active, or outline button
                  if (widget.inStock && details.threshold > 0 && widget.onApplyScheme != null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 36,
                      child: isActive
                          ? ElevatedButton.icon(
                              onPressed: widget.onApplyScheme,
                              icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                              label: Text(
                                '✓ Scheme Applied (+${details.threshold} Units)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669), // Solid pressed emerald
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: widget.onApplyScheme,
                              icon: const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF15803D)),
                              label: Text(
                                'Apply Scheme (+${details.threshold} Units)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                side: const BorderSide(color: Color(0xFF86EFAC), width: 1.1),
                                backgroundColor: const Color(0xFFECFDF5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
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
