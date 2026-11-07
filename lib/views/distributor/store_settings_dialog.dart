import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/app_settings.dart';
import '../../services/database_service.dart';

class StoreSettingsDialog extends StatefulWidget {
  final AppSettings settings;

  const StoreSettingsDialog({super.key, required this.settings});

  @override
  State<StoreSettingsDialog> createState() => _StoreSettingsDialogState();
}

class _StoreSettingsDialogState extends State<StoreSettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _masterPinController;
  late TextEditingController _staffPinController;
  bool _isSaving = false;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.storeName);
    _phoneController = TextEditingController(text: widget.settings.whatsappPhone);
    _masterPinController = TextEditingController(text: widget.settings.masterPin);
    _staffPinController = TextEditingController(text: widget.settings.staffPin);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _masterPinController.dispose();
    _staffPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final updated = widget.settings.copyWith(
      storeName: _nameController.text.trim(),
      whatsappPhone: _phoneController.text.replaceAll(RegExp(r'\D'), '').trim(),
      masterPin: _masterPinController.text.trim(),
      staffPin: _staffPinController.text.trim(),
    );

    await DatabaseService.instance.updateSettings(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distributor Desk settings saved successfully!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  Future<void> _handleSeedData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Sample Catalog Data?'),
        content: const Text(
          'This will populate Cloud Firestore with standard wholesale products and test retailers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Seed Now'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSeeding = true);
      await DatabaseService.instance.seedInitialData();
      if (mounted) {
        setState(() => _isSeeding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample catalog data seeded to Cloud Firestore!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_rounded, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Store & Security Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Store Name
              const Text('Distributor / Store Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                decoration: const InputDecoration(hintText: 'Apex Wholesale Distributors'),
              ),
              const SizedBox(height: 12),

              // WhatsApp Phone
              const Text('Orders WhatsApp Phone Number (with Country Code, no +) *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().length < 10 ? 'Valid WhatsApp number' : null,
                decoration: const InputDecoration(hintText: '917002796068'),
              ),
              const SizedBox(height: 12),

              // Master PIN & Staff PIN
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Master PIN (Admin) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _masterPinController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: (v) => v == null || v.trim().length != 4 ? '4 digits' : null,
                          decoration: const InputDecoration(counterText: '', hintText: '5075'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Staff PIN (Counter) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _staffPinController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: (v) => v == null || v.trim().length != 4 ? '4 digits' : null,
                          decoration: const InputDecoration(counterText: '', hintText: '1122'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cloud Seed Tool
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, size: 20, color: AppTheme.slate700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Seed Sample Products to Cloud Firestore',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isSeeding ? null : _handleSeedData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.slate800,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: _isSeeding
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Seed', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Settings'),
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

