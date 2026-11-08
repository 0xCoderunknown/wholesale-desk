import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/retailer.dart';
import '../../services/repository_manager.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';

/// Compact 44px sticky bar displayed beneath the AppBar in Salesman Mode.
/// Provides sub-millisecond route filtering, instant retailer switching,
/// and cart isolation safeguards.
class SalesmanRouteBar extends StatefulWidget {
  const SalesmanRouteBar({super.key});

  @override
  State<SalesmanRouteBar> createState() => _SalesmanRouteBarState();
}

class _SalesmanRouteBarState extends State<SalesmanRouteBar> {
  String _selectedRoute = 'All Routes';

  void _openRetailerPickerSheet(BuildContext context, List<Retailer> allRetailers) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) {
        return _RetailerPickerModal(
          initialRoute: _selectedRoute,
          allRetailers: allRetailers,
          onRetailerSelected: (selected) {
            _handleSelectRetailer(context, selected);
          },
        );
      },
    );
  }

  Future<void> _handleSelectRetailer(BuildContext context, Retailer selectedRetailer) async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();

    // If tapping the already active retailer, do nothing
    if (auth.currentRetailer?.id == selectedRetailer.id) {
      return;
    }

    // Cart Isolation Guard:
    // If cart is empty, switch immediately.
    // If cart has items, prompt the salesman to prevent cross-shop corruption.
    if (cart.itemCount == 0) {
      auth.switchSalesmanRetailer(selectedRetailer);
    } else {
      final currentShop = auth.currentRetailer?.storeName ?? 'Current Shop';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Text('Switch Active Shop?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(
            'Active Cart has ${cart.itemCount} item(s) for $currentShop. Switching shops will clear the cart. Proceed?',
            style: const TextStyle(fontSize: 13, color: AppTheme.slate600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Cart', style: TextStyle(color: AppTheme.slate600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.outOfStockRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear & Switch'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        cart.clear();
        auth.switchSalesmanRetailer(selectedRetailer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final activeRetailer = auth.currentRetailer;

    return StreamBuilder<List<Retailer>>(
      stream: RepositoryManager.instance.getRetailersStream(),
      builder: (context, snapshot) {
        final retailers = snapshot.data ?? [];

        // Extract distinct non-empty routes
        final routeSet = <String>{'All Routes'};
        for (final r in retailers) {
          if (r.route.trim().isNotEmpty) {
            routeSet.add(r.route.trim());
          }
        }
        final routes = routeSet.toList();

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: AppTheme.slate900,
            border: Border(
              bottom: BorderSide(color: AppTheme.slate700, width: 1),
            ),
          ),
          child: Row(
            children: [
              // 1. Route Dropdown Selector
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.slate800,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.slate700),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: routes.contains(_selectedRoute) ? _selectedRoute : 'All Routes',
                    dropdownColor: AppTheme.slate900,
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppTheme.primaryLight),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    items: routes.map((rt) {
                      final label = rt == 'All Routes' ? '📍 All Routes' : '📍 $rt';
                      return DropdownMenuItem(
                        value: rt,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRoute = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Retailer Shop Picker Pill (Opens bottom sheet search)
              Expanded(
                child: Tooltip(
                  message: 'Switch Active Shop',
                  child: InkWell(
                    onTap: () => _openRetailerPickerSheet(context, retailers),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.slate800,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 14, color: AppTheme.whatsappGreen),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activeRetailer != null
                                  ? 'Shop: ${activeRetailer.storeName}'
                                  : 'Select Retailer...',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppTheme.slate300),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Instant in-memory searchable bottom sheet to select a shop along the route.
class _RetailerPickerModal extends StatefulWidget {
  final String initialRoute;
  final List<Retailer> allRetailers;
  final ValueChanged<Retailer> onRetailerSelected;

  const _RetailerPickerModal({
    required this.initialRoute,
    required this.allRetailers,
    required this.onRetailerSelected,
  });

  @override
  State<_RetailerPickerModal> createState() => _RetailerPickerModalState();
}

class _RetailerPickerModalState extends State<_RetailerPickerModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  late String _activeRoute;

  @override
  void initState() {
    super.initState();
    _activeRoute = widget.initialRoute;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentId = auth.currentRetailer?.id;
    final query = _searchCtrl.text.trim().toLowerCase();

    // Filter by route and search query in-memory (<1ms response)
    final filtered = widget.allRetailers.where((r) {
      if (_activeRoute != 'All Routes' && r.route.trim().toLowerCase() != _activeRoute.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final nameMatch = r.storeName.toLowerCase().contains(query);
        final phoneMatch = r.mobile.contains(query);
        final routeMatch = r.route.toLowerCase().contains(query);
        return nameMatch || phoneMatch || routeMatch;
      }
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag pill handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header: Title & Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Select Retailer on Beat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${filtered.length} shops',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate500),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search input field
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search shop name, mobile, or route...',
              hintStyle: const TextStyle(fontSize: 12.5, color: AppTheme.slate400),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.slate500),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.slate50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Retailers List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching retailers found',
                      style: TextStyle(fontSize: 13, color: AppTheme.slate400),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.slate100),
                    itemBuilder: (context, index) {
                      final r = filtered[index];
                      final isSelected = r.id == currentId;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected ? AppTheme.primary : AppTheme.slate100,
                          child: Icon(
                            Icons.store_rounded,
                            size: 18,
                            color: isSelected ? Colors.white : AppTheme.slate600,
                          ),
                        ),
                        title: Text(
                          r.storeName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppTheme.primaryDark : AppTheme.slate900,
                          ),
                        ),
                        subtitle: Text(
                          '${r.route.isNotEmpty ? r.route : 'Unassigned'} • ${r.mobile}',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.slate500),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, size: 20, color: AppTheme.primary)
                            : const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.slate400),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onRetailerSelected(r);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
