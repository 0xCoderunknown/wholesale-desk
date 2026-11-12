import 'package:material_ui/material_ui.dart';
import '../../config/theme.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final VoidCallback? onSubmit;

  const NumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onDelete,
    required this.onClear,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 8),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 8),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 8),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyButton(
              label: key,
              onTap: () => onKeyPressed(key),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyButton(
              label: 'CLR',
              textColor: AppTheme.outOfStockRed,
              onTap: onClear,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyButton(
              label: '0',
              onTap: () => onKeyPressed('0'),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _KeyButton(
              icon: Icons.backspace_outlined,
              textColor: AppTheme.slate600,
              onTap: onDelete,
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? textColor;
  final VoidCallback onTap;

  const _KeyButton({
    this.label,
    this.icon,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppTheme.slate100,
        splashColor: AppTheme.slate200,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.slate300, width: 1),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 20, color: textColor ?? AppTheme.slate800)
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: label == 'CLR' ? 13 : 20,
                    fontWeight: FontWeight.w700,
                    color: textColor ?? AppTheme.slate900,
                  ),
                ),
        ),
      ),
    );
  }
}

class PinDotsIndicator extends StatelessWidget {
  final int length;
  final int filledCount;
  final bool hasError;

  const PinDotsIndicator({
    super.key,
    this.length = 4,
    required this.filledCount,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filledCount;
        Color color = AppTheme.slate300;
        if (hasError) {
          color = AppTheme.outOfStockRed;
        } else if (isFilled) {
          color = AppTheme.primary;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        );
      }),
    );
  }
}

