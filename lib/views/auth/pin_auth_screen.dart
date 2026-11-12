import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../state/auth_provider.dart';
import '../widgets/numeric_keypad.dart';

class PinAuthScreen extends StatefulWidget {
  const PinAuthScreen({super.key});

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  // 0: Retailer Login (Mobile + 4-Digit PIN)
  // 1: Distributor Desk (4-Digit Master / Staff PIN)
  int _selectedTab = 0;

  final TextEditingController _mobileController = TextEditingController(text: '9876543210');
  String _enteredPin = '';
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });
      if (_enteredPin.length == 4) {
        _handleLogin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
    });
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();

    if (_selectedTab == 1) {
      // Distributor Desk login (Admin Master PIN or Staff PIN)
      final success = await auth.loginWithPin(_enteredPin);
      if (!success && mounted) {
        setState(() {
          _enteredPin = '';
        });
      }
    } else {
      // Retailer login (Mobile + 4-Digit PIN)
      final success = await auth.loginRetailer(
        mobile: _mobileController.text.trim(),
        pin: _enteredPin,
      );
      if (!success && mounted) {
        setState(() {
          _enteredPin = '';
        });
      }
    }
  }

  Future<void> _applyViaWhatsApp(String phone, String storeName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final msg = Uri.encodeComponent(
      'Hello $storeName, I would like to register my store for wholesale orders. Please provide my 4-digit PIN.',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _quickFillAdmin() {
    setState(() {
      _selectedTab = 1;
      _enteredPin = '5075';
    });
    _handleLogin();
  }

  void _quickFillStaff() {
    setState(() {
      _selectedTab = 1;
      _enteredPin = '1122';
    });
    _handleLogin();
  }

  void _quickFillSalesman() {
    setState(() {
      _selectedTab = 1;
      _enteredPin = '3344';
    });
    _handleLogin();
  }

  void _quickFillRetailer() {
    setState(() {
      _selectedTab = 0;
      _mobileController.text = '9876543210';
      _enteredPin = '1234';
    });
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.slate100,
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            final keyLabel = event.logicalKey.keyLabel;
            if (RegExp(r'^[0-9]$').hasMatch(keyLabel)) {
              _onDigit(keyLabel);
            } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
              _onDelete();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              _onClear();
            } else if (event.logicalKey == LogicalKeyboardKey.enter && _enteredPin.length == 4) {
              _handleLogin();
            }
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slate300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.slate900.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Brand Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppTheme.slate900,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.settings.storeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Text(
                                    auth.settings.isWooCommerce
                                        ? 'Connected: WooCommerce REST'
                                        : 'Connected: Firebase Cloud',
                                    style: const TextStyle(
                                      color: AppTheme.slate400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mode Toggle Tabs
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              label: 'Retailer Order Desk',
                              icon: Icons.shopping_bag_outlined,
                              isSelected: _selectedTab == 0,
                              onTap: () {
                                setState(() {
                                  _selectedTab = 0;
                                  _enteredPin = '';
                                  auth.clearError();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              label: 'Distributor Desk',
                              icon: Icons.admin_panel_settings_outlined,
                              isSelected: _selectedTab == 1,
                              onTap: () {
                                setState(() {
                                  _selectedTab = 1;
                                  _enteredPin = '';
                                  auth.clearError();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_selectedTab == 0) ...[
                          const Text(
                            'Enter Retailer Mobile Number:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.slate700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                              prefixText: '+91 ',
                              prefixStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.slate800,
                              ),
                              hintText: '10-digit Indian mobile number',
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => _mobileController.clear(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Enter Retailer 4-Digit Security PIN:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.slate700,
                            ),
                          ),
                        ] else ...[
                          const Center(
                            child: Text(
                              'Enter 4-Digit Master / Staff / Salesman PIN:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.slate800,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // PIN Dots Indicator
                        Center(
                          child: PinDotsIndicator(
                            filledCount: _enteredPin.length,
                            hasError: auth.errorMessage != null,
                          ),
                        ),

                        // Error Banner
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.outOfStockRedBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.outOfStockRed.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 14,
                                  color: AppTheme.outOfStockRed,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(
                                      color: AppTheme.outOfStockRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Touch / Counter Keypad
                        NumericKeypad(
                          onKeyPressed: _onDigit,
                          onDelete: _onDelete,
                          onClear: _onClear,
                          onSubmit: _enteredPin.length == 4 ? _handleLogin : null,
                        ),

                        const SizedBox(height: 16),

                        // Submit Button
                        ElevatedButton.icon(
                          onPressed: auth.isLoading || _enteredPin.length < 4
                              ? null
                              : _handleLogin,
                          icon: auth.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: Text(
                            _selectedTab == 0 ? 'Access Retailer Catalog' : 'Enter Distributor Desk',
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                          ),
                        ),

                        // Retailer Apply via WhatsApp CTA (matching login-modal.php)
                        if (_selectedTab == 0) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _applyViaWhatsApp(
                                auth.settings.whatsappPhone,
                                auth.settings.storeName,
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.whatsappGreen),
                              label: const Text(
                                'Apply for Retailer Account via WhatsApp',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.slate600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Quick Demo Pills Footer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppTheme.slate50,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
                      border: Border(top: BorderSide(color: AppTheme.slate200)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ QUICK DEMO CREDENTIALS:',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildQuickChip(
                              label: 'Admin (Master 5075)',
                              color: AppTheme.primary,
                              onTap: _quickFillAdmin,
                            ),
                            _buildQuickChip(
                              label: 'Staff (PIN 1122)',
                              color: AppTheme.slate700,
                              onTap: _quickFillStaff,
                            ),
                            _buildQuickChip(
                              label: 'Salesman (PIN 3344)',
                              color: const Color(0xFFD97706),
                              onTap: _quickFillSalesman,
                            ),
                            _buildQuickChip(
                              label: 'Retailer (PIN 1234)',
                              color: const Color(0xFF2563EB),
                              onTap: _quickFillRetailer,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      elevation: isSelected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppTheme.primary : AppTheme.slate500,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.slate900 : AppTheme.slate600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
