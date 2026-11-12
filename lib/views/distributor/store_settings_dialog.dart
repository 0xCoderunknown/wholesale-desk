import 'package:material_ui/material_ui.dart';
import '../../config/theme.dart';
import '../../models/app_settings.dart';
import '../../services/repository_manager.dart';

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
  late TextEditingController _salesmanPinController;
  late TextEditingController _wpUrlController;
  late String _backendType; // 'firebase' | 'woocommerce'
  late bool _enforceMoq;
  bool _isSaving = false;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.storeName);
    _phoneController = TextEditingController(text: widget.settings.whatsappPhone);
    _masterPinController = TextEditingController(text: widget.settings.masterPin);
    _staffPinController = TextEditingController(text: widget.settings.staffPin);
    _salesmanPinController = TextEditingController(text: widget.settings.salesmanPin);
    _wpUrlController = TextEditingController(text: widget.settings.wpBaseUrl);
    _backendType = widget.settings.backendType;
    _enforceMoq = widget.settings.enforceMoq;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _masterPinController.dispose();
    _staffPinController.dispose();
    _salesmanPinController.dispose();
    _wpUrlController.dispose();
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
      salesmanPin: _salesmanPinController.text.trim(),
      backendType: _backendType,
      wpBaseUrl: _wpUrlController.text.trim(),
      enforceMoq: _enforceMoq,
    );

    RepositoryManager.instance.switchBackend(
      backendType: _backendType,
      wpBaseUrl: _wpUrlController.text.trim(),
    );
    await RepositoryManager.instance.updateSettings(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings saved! Active Backend: ${_backendType == 'woocommerce' ? 'WordPress WooCommerce REST' : 'Firebase Cloud Firestore'}',
          ),
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
          'This will populate the active backend with standard wholesale products and test retailers.',
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
      await RepositoryManager.instance.seedInitialData();
      if (mounted) {
        setState(() => _isSeeding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample catalog data refreshed successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  Widget _buildBackendOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _backendType == value;

    return InkWell(
      onTap: () => setState(() => _backendType = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primarySurface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.slate300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppTheme.primary : AppTheme.slate500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.primaryDark : AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected ? AppTheme.primary : AppTheme.slate400,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings_rounded, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Store & Backend Settings',
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

                // Backend Provider Switcher
                const Text(
                  'Select Active Backend Provider *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate800),
                ),
                const SizedBox(height: 8),
                _buildBackendOption(
                  value: 'firebase',
                  title: 'Google Cloud Firestore (Firebase)',
                  subtitle: 'Serverless, realtime sync (/settings, /retailers, /products)',
                  icon: Icons.local_fire_department_rounded,
                ),
                const SizedBox(height: 8),
                _buildBackendOption(
                  value: 'woocommerce',
                  title: 'WordPress + WooCommerce (REST API)',
                  subtitle: 'Direct connection to woocommerce-whatsapp-commerce (/wp-json/swac/v1/)',
                  icon: Icons.storefront_rounded,
                ),
                const SizedBox(height: 14),

                // WordPress URL field if WooCommerce selected
                if (_backendType == 'woocommerce') ...[
                  const Text(
                    'WordPress Site URL (with swac/v1 plugin) *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _wpUrlController,
                    validator: (v) {
                      if (_backendType == 'woocommerce' && (v == null || v.trim().isEmpty)) {
                        return 'WordPress Site URL is required';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link_rounded, size: 18),
                      hintText: 'https://mywholesalestore.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // MOQ Enforcement Toggle (Requirement #2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.slate300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.rule_folder_rounded, size: 20, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enforce MOQ on Orders',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                            ),
                            Text(
                              _enforceMoq
                                  ? 'Retailers must order at least the MOQ quantity.'
                                  : 'MOQ relaxed: Retailers can order any quantity (1+).',
                              style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enforceMoq,
                        activeTrackColor: AppTheme.primary,
                        onChanged: (val) => setState(() => _enforceMoq = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

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

                // Master PIN, Staff PIN, and Salesman PIN
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Master PIN *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Staff PIN *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Salesman PIN *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _salesmanPinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            validator: (v) => v == null || v.trim().length != 4 ? '4 digits' : null,
                            decoration: const InputDecoration(counterText: '', hintText: '3344'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Seed / Sync Tool
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
                          'Refresh / Seed Catalog Data',
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
                            : const Text('Sync', style: TextStyle(fontSize: 11)),
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
      ),
    );
  }
}
