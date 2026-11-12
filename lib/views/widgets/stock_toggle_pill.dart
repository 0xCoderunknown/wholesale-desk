import 'package:material_ui/material_ui.dart';
import '../../config/theme.dart';

class StockTogglePill extends StatelessWidget {
  final bool inStock;
  final bool enabled;
  final VoidCallback? onToggle;
  final bool compact;

  const StockTogglePill({
    super.key,
    required this.inStock,
    this.enabled = true,
    this.onToggle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = inStock ? AppTheme.inStockGreenBg : AppTheme.outOfStockRedBg;
    final fgColor = inStock ? AppTheme.inStockGreen : AppTheme.outOfStockRed;
    final text = inStock ? 'IN STOCK' : 'OUT OF STOCK';
    final icon = inStock ? Icons.check_circle_rounded : Icons.cancel_rounded;

    final pillWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: fgColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fgColor,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: 3),
            Icon(Icons.swap_horiz_rounded, size: 12, color: fgColor.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );

    if (!enabled || onToggle == null) {
      return pillWidget;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        hoverColor: fgColor.withValues(alpha: 0.08),
        splashColor: fgColor.withValues(alpha: 0.15),
        child: Tooltip(
          message: inStock ? 'Click to mark OUT OF STOCK' : 'Click to mark IN STOCK',
          child: pillWidget,
        ),
      ),
    );
  }
}
