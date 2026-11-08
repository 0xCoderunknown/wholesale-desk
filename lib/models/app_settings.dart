class AppSettings {
  final String whatsappPhone;
  final String storeName;
  final String masterPin;
  final String staffPin;
  final String salesmanPin;
  final String backendType; // 'firebase' | 'woocommerce'
  final String wpBaseUrl; // e.g. 'https://mywholesalestore.com'
  final bool enforceMoq; // Distributor can turn off MOQ enforcement

  const AppSettings({
    required this.whatsappPhone,
    required this.storeName,
    required this.masterPin,
    required this.staffPin,
    this.salesmanPin = '3344',
    this.backendType = 'firebase',
    this.wpBaseUrl = '',
    this.enforceMoq = true,
  });

  bool get isWooCommerce => backendType.toLowerCase() == 'woocommerce';
  bool get isFirebase => backendType.toLowerCase() == 'firebase';

  factory AppSettings.defaults() {
    return const AppSettings(
      whatsappPhone: '917002796068',
      storeName: 'Apex Wholesale Distributors',
      masterPin: '5075',
      staffPin: '1122',
      salesmanPin: '3344',
      backendType: 'firebase',
      wpBaseUrl: '',
      enforceMoq: true,
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      whatsappPhone: map['whatsapp_phone']?.toString() ?? '917002796068',
      storeName: map['store_name']?.toString() ?? 'Apex Wholesale Distributors',
      masterPin: map['master_pin']?.toString() ?? '5075',
      staffPin: map['staff_pin']?.toString() ?? '1122',
      salesmanPin: map['salesman_pin']?.toString() ?? '3344',
      backendType: map['backend_type']?.toString() ?? 'firebase',
      wpBaseUrl: map['wp_base_url']?.toString() ?? '',
      enforceMoq: map['enforce_moq'] is bool ? map['enforce_moq'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'whatsapp_phone': whatsappPhone,
      'store_name': storeName,
      'master_pin': masterPin,
      'staff_pin': staffPin,
      'salesman_pin': salesmanPin,
      'backend_type': backendType,
      'wp_base_url': wpBaseUrl,
      'enforce_moq': enforceMoq,
    };
  }

  AppSettings copyWith({
    String? whatsappPhone,
    String? storeName,
    String? masterPin,
    String? staffPin,
    String? salesmanPin,
    String? backendType,
    String? wpBaseUrl,
    bool? enforceMoq,
  }) {
    return AppSettings(
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      storeName: storeName ?? this.storeName,
      masterPin: masterPin ?? this.masterPin,
      staffPin: staffPin ?? this.staffPin,
      salesmanPin: salesmanPin ?? this.salesmanPin,
      backendType: backendType ?? this.backendType,
      wpBaseUrl: wpBaseUrl ?? this.wpBaseUrl,
      enforceMoq: enforceMoq ?? this.enforceMoq,
    );
  }
}
