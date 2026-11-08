import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/scheme_helper.dart';

/// High-density inline scheme banner component (unified across mobile and desktop).
/// Renders a single-line compact strip with scheme details and an inline 1-click [APPLY] button.
class SchemeInlineStrip extends StatefulWidget {
  final Product product;
  final bool inStock;
  final bool isAlreadyActive;
  final VoidCallback? onApplyScheme;
  final VoidCallback? onRemoveScheme;
  final bool isDesktop;

  const SchemeInlineStrip({
    super.key,
    required this.product,
    required this.inStock,
    this.isAlreadyActive = false,
    this.onApplyScheme,
    this.onRemoveScheme,
    this.isDesktop = false,
  });

  @override
  State<SchemeInlineStrip> createState() => _SchemeInlineStripState();
}

class _SchemeInlineStripState extends State<SchemeInlineStrip> {
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

    // 1. Static info strip for continuous/percentage schemes (auto-applied)
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

    // 2. Tiered schemes: Clean, single-line horizontal strip with inline [APPLY] button
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFFDE047),
          width: 0.9,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Text(isActive ? '✓ ' : '🏷️ ', style: const TextStyle(fontSize: 12)),
          Expanded(
            child: Tooltip(
              message: details.breakdownCopy,
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
          ),
          const SizedBox(width: 8),

          // Sized [APPLY] / [REMOVE] Action Button
          if (widget.inStock && details.threshold > 0 && (widget.onApplyScheme != null || widget.onRemoveScheme != null))
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isActive
                    ? (widget.onRemoveScheme ?? widget.onApplyScheme)
                    : widget.onApplyScheme,
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.close_rounded : Icons.bolt_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'REMOVE' : 'APPLY',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

