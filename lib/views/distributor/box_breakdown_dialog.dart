import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../models/product.dart';

/// Lightweight "Dispatch Box Breakdown Calculator" utility for warehouse staff and distributors.
/// Converts any ordered piece quantity into physical cartons and loose picking units.
class BoxBreakdownDialog extends StatefulWidget {
  final List<Product> products;
  final Product? initialProduct;
  final int? initialCartonPack;

  const BoxBreakdownDialog({
    super.key,
    required this.products,
    this.initialProduct,
    this.initialCartonPack,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Product> products,
    Product? initialProduct,
    int? initialCartonPack,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BoxBreakdownDialog(
        products: products,
        initialProduct: initialProduct,
        initialCartonPack: initialCartonPack,
      ),
    );
  }

  @override
  State<BoxBreakdownDialog> createState() => _BoxBreakdownDialogState();
}

class _BoxBreakdownDialogState extends State<BoxBreakdownDialog> {
  late TextEditingController _qtyController;
  late TextEditingController _boxSizeController;

  Product? _selectedProduct;
  int _orderedQty = 0;
  int _boxSize = 24;

  static const List<int> _quickBoxSizes = [6, 10, 12, 20, 24, 48, 96];

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.initialProduct;

    if (_selectedProduct != null && _selectedProduct!.hasCartonPack) {
      _boxSize = _selectedProduct!.cartonPack;
    } else if (widget.initialCartonPack != null && widget.initialCartonPack! > 0) {
      _boxSize = widget.initialCartonPack!;
    } else {
      _boxSize = 24;
    }

    _orderedQty = _boxSize; // default to 1 box
    _qtyController = TextEditingController(text: '$_orderedQty');
    _boxSizeController = TextEditingController(text: '$_boxSize');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _boxSizeController.dispose();
    super.dispose();
  }

  void _onProductSelected(Product? p) {
    setState(() {
      _selectedProduct = p;
      if (p != null && p.hasCartonPack) {
        _boxSize = p.cartonPack;
        _boxSizeController.text = '$_boxSize';
      }
    });
  }

  void _updateQuantity(int newQty) {
    final validQty = newQty < 0 ? 0 : newQty;
    setState(() {
      _orderedQty = validQty;
      _qtyController.text = '$_orderedQty';
    });
  }

  void _updateBoxSize(int newSize) {
    final validSize = newSize <= 0 ? 1 : newSize;
    setState(() {
      _boxSize = validSize;
      _boxSizeController.text = '$_boxSize';
    });
  }

  @override
  Widget build(BuildContext context) {
    final fullBoxes = _boxSize > 0 ? _orderedQty ~/ _boxSize : 0;
    final looseUnits = _boxSize > 0 ? _orderedQty % _boxSize : _orderedQty;
    final boxedUnits = fullBoxes * _boxSize;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: const Text('📦', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Box Breakdown Calculator',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Fast van loading & carton dispatch calculator',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.slate500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.slate500),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Optional Product Selector
              if (widget.products.isNotEmpty) ...[
                const Text(
                  'SELECT PRODUCT (OPTIONAL)',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.slate600, letterSpacing: 0.3),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.slate300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Product?>(
                      isExpanded: true,
                      value: _selectedProduct,
                      hint: const Text('Select product to auto-fill box size...', style: TextStyle(fontSize: 12, color: AppTheme.slate400)),
                      items: [
                        const DropdownMenuItem<Product?>(
                          value: null,
                          child: Text('Custom Box Size (No product selected)', style: TextStyle(fontSize: 12, color: AppTheme.slate600)),
                        ),
                        ...widget.products.map(
                          (p) => DropdownMenuItem<Product?>(
                            value: p,
                            child: Text(
                              '${p.name} (${p.brand}) ${p.hasCartonPack ? '• Box: ${p.cartonPack}' : ''}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: _onProductSelected,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 2. Carton / Case Pack Size Input
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'CARTON / BOX PACK SIZE',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.slate600, letterSpacing: 0.3),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 36,
                    child: TextField(
                      controller: _boxSizeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixText: 'pcs',
                        suffixStyle: const TextStyle(fontSize: 10, color: AppTheme.slate400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onChanged: (v) {
                        final val = int.tryParse(v);
                        if (val != null && val > 0) {
                          setState(() => _boxSize = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Quick Box Size Chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _quickBoxSizes.map((size) {
                  final isSelected = _boxSize == size;
                  return ChoiceChip(
                    label: Text('$size'),
                    selected: isSelected,
                    onSelected: (_) => _updateBoxSize(size),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.slate700,
                    ),
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: AppTheme.slate100,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 3. Total Quantity Ordered Input
              const Text(
                'TOTAL ORDER QUANTITY (PIECES)',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.slate600, letterSpacing: 0.3),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.numbers_rounded, size: 20, color: AppTheme.slate400),
                        hintText: 'Enter quantity...',
                        filled: true,
                        fillColor: AppTheme.slate50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (v) {
                        final val = int.tryParse(v);
                        setState(() => _orderedQty = val ?? 0);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _updateQuantity(0),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick Adder Buttons
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _quickAddButton('+1', () => _updateQuantity(_orderedQty + 1)),
                  _quickAddButton('+5', () => _updateQuantity(_orderedQty + 5)),
                  _quickAddButton('+10', () => _updateQuantity(_orderedQty + 10)),
                  _quickAddButton('+1 Box ($_boxSize)', () => _updateQuantity(_orderedQty + _boxSize), isHighlight: true),
                  _quickAddButton('+5 Boxes (${_boxSize * 5})', () => _updateQuantity(_orderedQty + (_boxSize * 5))),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Output Display: Physical Carton & Loose Breakdown Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Slate 900
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'DISPATCH BREAKDOWN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Primary Output Display
                    if (_orderedQty == 0)
                      const Text(
                        'Enter quantity to calculate cartons & loose units',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      )
                    else if (_boxSize <= 1)
                      Text(
                        '🧴 $_orderedQty Loose Pieces (No box pack)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8)),
                      )
                    else
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (fullBoxes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                              ),
                              child: Text(
                                '📦 $fullBoxes Full ${fullBoxes == 1 ? 'Box' : 'Boxes'} ($boxedUnits pcs)',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8)),
                              ),
                            ),
                          if (fullBoxes > 0 && looseUnits > 0)
                            const Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                          if (looseUnits > 0 || fullBoxes == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: fullBoxes == 0 ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                '🧴 $looseUnits Loose ${looseUnits == 1 ? 'Piece' : 'Pieces'}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: fullBoxes == 0 ? const Color(0xFFFBBF24) : Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 14),

                    // Breakdown Tally Metrics
                    const Divider(color: Color(0xFF334155), height: 1),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _metricText('Total Pieces', '$_orderedQty pcs'),
                        _metricText('Carton Size', '$_boxSize pcs/box'),
                        _metricText('Full Boxes', '$fullBoxes'),
                        _metricText('Loose Units', '$looseUnits'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Done Button
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAddButton(String label, VoidCallback onTap, {bool isHighlight = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isHighlight ? const Color(0xFFEFF6FF) : AppTheme.slate100,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: isHighlight ? const Color(0xFF93C5FD) : AppTheme.slate300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isHighlight ? const Color(0xFF1E40AF) : AppTheme.slate700,
          ),
        ),
      ),
    );
  }

  Widget _metricText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }
}
