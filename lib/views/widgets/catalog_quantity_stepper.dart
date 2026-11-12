import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../models/product.dart';

enum StepperStyle {
  compact,
  fullWidth,
  drawer,
}

/// Canonical wholesale quantity stepper with:
/// 1. [-] Decrement button (enforces MOQ floor when enforceMoq is active)
/// 2. [qty] Inline editable TextField by default (in-place typing for counter speed)
/// 3. [+] Increment button
/// 4. [🗑️] 1-Tap direct delete button to remove the entire addition
class CatalogQuantityStepper extends StatefulWidget {
  final Product product;
  final int quantity;
  final bool enforceMoq;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDirectDelete;
  final ValueChanged<int>? onQuantityChanged;
  final StepperStyle style;

  const CatalogQuantityStepper({
    super.key,
    required this.product,
    required this.quantity,
    required this.enforceMoq,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDirectDelete,
    this.onQuantityChanged,
    this.style = StepperStyle.compact,
  });

  @override
  State<CatalogQuantityStepper> createState() => _CatalogQuantityStepperState();
}

class _CatalogQuantityStepperState extends State<CatalogQuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(CatalogQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity && !_focusNode.hasFocus) {
      _controller.text = '${widget.quantity}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _commitQuantity(_controller.text);
    }
  }

  void _commitQuantity(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null || parsed <= 0) {
      if (parsed == 0) {
        widget.onDirectDelete();
      } else {
        _controller.text = '${widget.quantity}';
      }
      return;
    }

    final minBound = widget.product.minOrderQuantity(enforceMoq: widget.enforceMoq);
    if (widget.enforceMoq && parsed < minBound) {
      widget.onQuantityChanged?.call(minBound);
      _controller.text = '$minBound';
    } else {
      widget.onQuantityChanged?.call(parsed);
      _controller.text = '$parsed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final minBound = widget.product.minOrderQuantity(enforceMoq: widget.enforceMoq);
    final isAtMinBound = widget.enforceMoq && (widget.quantity <= minBound);

    if (widget.style == StepperStyle.fullWidth) {
      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.primary, width: 1.4),
        ),
        child: Row(
          children: [
            // Decrement target (disabled at MOQ floor)
            InkWell(
              onTap: isAtMinBound ? null : widget.onDecrement,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
              child: Container(
                height: 38,
                width: 32,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove_rounded,
                  size: 16,
                  color: isAtMinBound ? AppTheme.slate300 : AppTheme.primary,
                ),
              ),
            ),
            // Inline Editable Quantity Field (Directly editable by default!)
            Expanded(
              child: Center(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _commitQuantity,
                ),
              ),
            ),
            // Increment target
            InkWell(
              onTap: widget.onIncrement,
              child: Container(
                height: 38,
                width: 32,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
            ),
            // 1-Tap Direct Delete Target (Dustbin icon)
            InkWell(
              onTap: widget.onDirectDelete,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
              child: Container(
                height: 38,
                width: 32,
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppTheme.slate200, width: 0.9)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppTheme.outOfStockRed,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.style == StepperStyle.drawer) {
      return Container(
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.slate300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: isAtMinBound ? null : widget.onDecrement,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
              child: Container(
                width: 28,
                height: 30,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove_rounded,
                  size: 15,
                  color: isAtMinBound ? AppTheme.slate300 : AppTheme.slate700,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: _commitQuantity,
              ),
            ),
            InkWell(
              onTap: widget.onIncrement,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
              child: Container(
                width: 28,
                height: 30,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 15,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default: StepperStyle.compact
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primary, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: isAtMinBound ? null : widget.onDecrement,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
            child: Container(
              width: 28,
              height: 32,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove_rounded,
                size: 15,
                color: isAtMinBound ? AppTheme.slate300 : AppTheme.primary,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IntrinsicWidth(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: _commitQuantity,
              ),
            ),
          ),
          InkWell(
            onTap: widget.onIncrement,
            child: Container(
              width: 28,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 15,
                color: AppTheme.primary,
              ),
            ),
          ),
          InkWell(
            onTap: widget.onDirectDelete,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
            child: Container(
              width: 26,
              height: 32,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppTheme.slate200, width: 0.8)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 14,
                color: AppTheme.outOfStockRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
