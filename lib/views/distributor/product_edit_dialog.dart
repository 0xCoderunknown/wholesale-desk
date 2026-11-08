import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/formatters.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../services/scheme_helper.dart';
import '../widgets/scheme_guide_dialog.dart';
import '../widgets/stock_toggle_pill.dart';

class ProductEditDialog extends StatefulWidget {
  final Product? product; // null for new product

  const ProductEditDialog({super.key, this.product});

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _schemeController;
  late TextEditingController _mrpController;
  late TextEditingController _ptrController;
  late TextEditingController _moqController;
  late TextEditingController _cartonPackController;
  late bool _inStock;

  SchemeClassification _schemePreview = SchemeClassification.none;

  bool get isEditing => widget.product != null;

  double get _mrp => double.tryParse(_mrpController.text.trim()) ?? 0.0;
  double get _ptr => double.tryParse(_ptrController.text.trim()) ?? 0.0;
  bool get _hasValidRates => _mrp > 0 && _ptr > 0;
  double get _margin => _mrp - _ptr;
  double get _marginPercent => _mrp > 0 ? ((_mrp - _ptr) / _mrp) * 100 : 0.0;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _schemeController = TextEditingController(text: p?.scheme ?? '');
    _mrpController = TextEditingController(text: p != null ? p.mrp.toString() : '');
    _ptrController = TextEditingController(text: p != null ? p.ptr.toString() : '');
    _moqController = TextEditingController(text: p != null ? p.moq.toString() : '1');
    _cartonPackController = TextEditingController(
      text: (p != null && p.cartonPack > 0) ? p.cartonPack.toString() : '',
    );
    _inStock = p?.inStock ?? true;

    _schemePreview = SchemeHelper.parsePreview(_schemeController.text);
    _mrpController.addListener(_onRateChanged);
    _ptrController.addListener(_onRateChanged);
    _schemeController.addListener(_onSchemeChanged);
  }

  void _onRateChanged() {
    setState(() {});
  }

  void _onSchemeChanged() {
    setState(() {
      _schemePreview = SchemeHelper.parsePreview(_schemeController.text);
    });
  }

  @override
  void dispose() {
    _mrpController.removeListener(_onRateChanged);
    _ptrController.removeListener(_onRateChanged);
    _schemeController.removeListener(_onSchemeChanged);
    _nameController.dispose();
    _brandController.dispose();
    _schemeController.dispose();
    _mrpController.dispose();
    _ptrController.dispose();
    _moqController.dispose();
    _cartonPackController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.product?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final mrp = double.tryParse(_mrpController.text.trim()) ?? 0.0;
    final ptr = double.tryParse(_ptrController.text.trim()) ?? 0.0;
    final moq = int.tryParse(_moqController.text.trim()) ?? 1;
    final cartonPack = int.tryParse(_cartonPackController.text.trim()) ?? 0;

    final product = Product(
      id: id,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      mrp: mrp,
      ptr: ptr,
      scheme: _schemeController.text.trim(),
      moq: moq,
      cartonPack: cartonPack,
      inStock: _inStock,
      imageUrl: '', // Binary zero-bloat, image empty
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.sizeOf(context).width > 560
            ? 520
            : (MediaQuery.sizeOf(context).width - 32).clamp(300.0, 520.0),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Bar
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Product Rates & Scheme' : 'Add New Wholesale Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 1. Product Name (autofocus + TextInputAction.next)
                const Text(
                  'Product Name & Variant *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Product Name is required' : null,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Dettol Antiseptic Liquid 500ml',
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Brand & Scheme Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Brand / Manufacturer *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _brandController,
                            textInputAction: TextInputAction.next,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Brand is required' : null,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Reckitt, Parle, ITC',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scheme / Offer String',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _schemeController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'e.g., 10+1 Free, 5% CD',
                            ),
                          ),
                          // Live Syntax Preview Badge
                          if (_schemePreview.type != SchemeType.none) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _schemePreview.type == SchemeType.freeGoods
                                    ? const Color(0xFFFEF3C7) // Amber 100
                                    : _schemePreview.type == SchemeType.percentage
                                        ? const Color(0xFFECFDF5) // Emerald 50
                                        : AppTheme.slate100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _schemePreview.type == SchemeType.freeGoods
                                      ? const Color(0xFFFDE68A)
                                      : _schemePreview.type == SchemeType.percentage
                                          ? const Color(0xFFA7F3D0)
                                          : AppTheme.slate300,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                _schemePreview.previewDescription,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _schemePreview.type == SchemeType.freeGoods
                                      ? const Color(0xFF92400E)
                                      : _schemePreview.type == SchemeType.percentage
                                          ? const Color(0xFF065F46)
                                          : AppTheme.slate600,
                                ),
                              ),
                            ),
                          ],
                          // Scheme Warning Alert Badge (Non-blocking)
                          if (_schemePreview.warning != null) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2), // Red 50
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5), // Red 300
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _schemePreview.warning!,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _showSchemeHelpDialog(context),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.help_outline_rounded, size: 13, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Press here to help with scheme',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2563EB),
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. MRP & PTR Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MRP (₹) *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _mrpController,
                            textInputAction: TextInputAction.next,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'MRP is required';
                              final val = double.tryParse(v.trim());
                              if (val == null || val <= 0) return 'Must be > 0';
                              return null;
                            },
                            decoration: const InputDecoration(hintText: '0.00'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PTR / Rate (₹) *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _ptrController,
                            textInputAction: TextInputAction.next,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'PTR is required';
                              final ptrVal = double.tryParse(v.trim());
                              if (ptrVal == null || ptrVal <= 0) return 'Must be > 0';
                              final mrpVal = double.tryParse(_mrpController.text.trim());
                              if (mrpVal != null && mrpVal > 0 && ptrVal > mrpVal) {
                                return 'PTR cannot exceed MRP';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(hintText: '0.00'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Dynamic Margin Calculation & Preview Strip
                if (_hasValidRates) ...[
                  const SizedBox(height: 8),
                  if (_ptr <= _mrp)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5), // Emerald 50
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 1), // Emerald 200
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '📈 Retailer Margin: ${AppFormatters.formatCurrency(_margin)} (${_marginPercent.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857), // Emerald 700
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2), // Red 50
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1), // Red 200
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '⚠️ Illegal Pricing: PTR exceeds MRP by ${AppFormatters.formatCurrency(_ptr - _mrp)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB91C1C), // Red 700
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 12),

                // 4. MOQ & Box / Carton Pack Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MOQ *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _moqController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'MOQ is required';
                              final val = int.tryParse(v.trim());
                              if (val == null || val < 1) return 'Must be ≥ 1';
                              return null;
                            },
                            decoration: const InputDecoration(hintText: '1'),
                          ),
                          if (_schemePreview.type == SchemeType.percentage) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Tip: Set MOQ to enforce minimum order quantity for this % discount.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857), // Emerald 700
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Box / Carton Pack',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _cartonPackController,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleSave(),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final val = int.tryParse(v.trim());
                              if (val == null || val < 0) return 'Must be ≥ 0';
                              return null;
                            },
                            decoration: const InputDecoration(hintText: 'Optional (e.g. 24)'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Stock Toggle Switch (Using signature StockTogglePill)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _inStock
                        ? AppTheme.inStockGreenBg.withValues(alpha: 0.3)
                        : AppTheme.outOfStockRedBg.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _inStock
                          ? AppTheme.inStockGreen.withValues(alpha: 0.3)
                          : AppTheme.outOfStockRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _inStock ? 'Current Status: IN STOCK' : 'Current Status: OUT OF STOCK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _inStock ? AppTheme.inStockGreen : AppTheme.outOfStockRed,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StockTogglePill(
                        inStock: _inStock,
                        compact: true,
                        enabled: true,
                        onToggle: () => setState(() => _inStock = !_inStock),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _handleSave,
                      child: Text(isEditing ? 'Save Changes' : 'Add to Catalog'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSchemeHelpDialog(BuildContext context) {
    SchemeGuideDialog.show(
      context,
      onSelectTemplate: (template) {
        _schemeController.text = template;
      },
    );
  }
}
