import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/product.dart';

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
  late TextEditingController _mrpController;
  late TextEditingController _ptrController;
  late TextEditingController _schemeController;
  late TextEditingController _moqController;
  late TextEditingController _cartonPackController;
  late bool _inStock;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _mrpController = TextEditingController(text: p != null ? p.mrp.toString() : '');
    _ptrController = TextEditingController(text: p != null ? p.ptr.toString() : '');
    _schemeController = TextEditingController(text: p?.scheme ?? '');
    _moqController = TextEditingController(text: p != null ? p.moq.toString() : '1');
    _cartonPackController = TextEditingController(
      text: (p != null && p.cartonPack > 0) ? p.cartonPack.toString() : '',
    );
    _inStock = p?.inStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _mrpController.dispose();
    _ptrController.dispose();
    _schemeController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
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
                  Text(
                    isEditing ? 'Edit Product Rates & Scheme' : 'Add New Wholesale Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Product Name
              const Text(
                'Product Name & Variant *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                decoration: const InputDecoration(
                  hintText: 'e.g., Dettol Antiseptic Liquid 500ml',
                ),
              ),
              const SizedBox(height: 12),

              // Brand & Scheme Row
              Row(
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
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
                          decoration: const InputDecoration(
                            hintText: 'e.g., 10+1 Free, 5% CD',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // MRP & PTR Row
              Row(
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Valid MRP' : null,
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Valid PTR' : null,
                          decoration: const InputDecoration(hintText: '0.00'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // MOQ & Box Size / Carton Pack Row
              Row(
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
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Valid MOQ' : null,
                          decoration: const InputDecoration(hintText: '1'),
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
                          'Box Size / Carton Pack (Optional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _cartonPackController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g. 24 or 144'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stock Toggle Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _inStock
                      ? AppTheme.inStockGreenBg.withValues(alpha: 0.4)
                      : AppTheme.outOfStockRedBg.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _inStock
                        ? AppTheme.inStockGreen.withValues(alpha: 0.3)
                        : AppTheme.outOfStockRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _inStock ? 'Current Status: IN STOCK' : 'Current Status: OUT OF STOCK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _inStock ? AppTheme.inStockGreen : AppTheme.outOfStockRed,
                      ),
                    ),
                    Switch(
                      value: _inStock,
                      activeTrackColor: AppTheme.inStockGreen,
                      onChanged: (v) => setState(() => _inStock = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Actions
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
    );
  }
}
