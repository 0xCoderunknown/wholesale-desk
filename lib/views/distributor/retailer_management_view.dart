import 'package:material_ui/material_ui.dart';
import '../../config/formatters.dart';
import '../../config/theme.dart';
import '../../models/retailer.dart';
import '../../services/repository_manager.dart';

class RetailerManagementView extends StatefulWidget {
  const RetailerManagementView({super.key});

  @override
  State<RetailerManagementView> createState() => _RetailerManagementViewState();
}

class _RetailerManagementViewState extends State<RetailerManagementView> {
  final RepositoryManager _repo = RepositoryManager.instance;
  String _searchQuery = '';

  void _showRetailerDialog([Retailer? retailer]) {
    final formKey = GlobalKey<FormState>();
    final storeController = TextEditingController(text: retailer?.storeName ?? '');
    final mobileController = TextEditingController(text: retailer?.mobile ?? '');
    final pinController = TextEditingController(text: retailer?.pin ?? '');
    final routeController = TextEditingController(text: retailer?.route ?? '');
    String status = retailer?.status ?? 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Row(
                    children: [
                      Icon(
                        retailer == null ? Icons.person_add_alt_1_rounded : Icons.manage_accounts_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        retailer == null ? 'Add Retailer PIN Account' : 'Edit Retailer Access',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Store Name
                  const Text('Store Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: storeController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    decoration: const InputDecoration(hintText: 'e.g., Sharma Medical & General'),
                  ),
                  const SizedBox(height: 12),

                  // Mobile & PIN
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mobile (Login) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: mobileController,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().length < 10 ? '10-digit mobile' : null,
                              decoration: const InputDecoration(hintText: '9876543210'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('4-Digit PIN *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: pinController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              validator: (v) => v == null || v.trim().length != 4 ? '4 digits' : null,
                              decoration: const InputDecoration(
                                counterText: '',
                                hintText: '1234',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Delivery Route
                  const Text('Delivery Route / Beat *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: routeController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    decoration: const InputDecoration(hintText: 'e.g., Market Road Route 2'),
                  ),
                  const SizedBox(height: 12),

                  // Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Status: ${status.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: status == 'active' ? AppTheme.inStockGreen : AppTheme.outOfStockRed,
                        ),
                      ),
                      Switch(
                        value: status == 'active',
                        activeTrackColor: AppTheme.inStockGreen,
                        onChanged: (val) {
                          setDialogState(() {
                            status = val ? 'active' : 'suspended';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final newRetailer = Retailer(
                            id: retailer?.id ?? 'ret_${DateTime.now().millisecondsSinceEpoch}',
                            storeName: storeController.text.trim(),
                            mobile: mobileController.text.trim(),
                            pin: pinController.text.trim(),
                            route: routeController.text.trim(),
                            status: status,
                          );
                          await _repo.saveRetailer(newRetailer);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: Text(retailer == null ? 'Create Account' : 'Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Retailer>>(
      stream: _repo.getRetailersStream(),
      builder: (context, snapshot) {
        final retailers = snapshot.data ?? [];
        final filtered = retailers.where((r) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return r.storeName.toLowerCase().contains(q) ||
              r.mobile.contains(q) ||
              r.route.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.slate200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                        hintText: 'Search retailers by store name, phone, or route...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showRetailerDialog(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Retailer'),
                  ),
                ],
              ),
            ),

            // Retailer List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No retailers found',
                        style: TextStyle(color: AppTheme.slate500),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final r = filtered[index];
                        final isActive = r.isActive;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppTheme.primarySurface : AppTheme.outOfStockRedBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.store_rounded,
                                    size: 20,
                                    color: isActive ? AppTheme.primary : AppTheme.outOfStockRed,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            r.storeName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.slate900,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isActive ? AppTheme.inStockGreenBg : AppTheme.outOfStockRedBg,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              r.status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: isActive ? AppTheme.inStockGreen : AppTheme.outOfStockRed,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Mobile: ${AppFormatters.formatIndianMobile(r.mobile)} • PIN: ${r.pin} • Route: ${r.route}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.slate600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.slate600),
                                      tooltip: 'Edit Retailer',
                                      onPressed: () => _showRetailerDialog(r),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.outOfStockRed),
                                      tooltip: 'Delete Retailer',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Retailer?'),
                                            content: Text('Are you sure you want to delete ${r.storeName}?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.outOfStockRed),
                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _repo.deleteRetailer(r.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
