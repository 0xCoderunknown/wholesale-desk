class AppSettings {
  final String whatsappPhone;
  final String storeName;
  final String masterPin;
  final String staffPin;

  const AppSettings({
    required this.whatsappPhone,
    required this.storeName,
    required this.masterPin,
    required this.staffPin,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      whatsappPhone: '917002796068',
      storeName: 'Apex Wholesale Distributors',
      masterPin: '5075',
      staffPin: '1122',
    );
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      whatsappPhone: map['whatsapp_phone']?.toString() ?? '917002796068',
      storeName: map['store_name']?.toString() ?? 'Apex Wholesale Distributors',
      masterPin: map['master_pin']?.toString() ?? '5075',
      staffPin: map['staff_pin']?.toString() ?? '1122',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'whatsapp_phone': whatsappPhone,
      'store_name': storeName,
      'master_pin': masterPin,
      'staff_pin': staffPin,
    };
  }

  AppSettings copyWith({
    String? whatsappPhone,
    String? storeName,
    String? masterPin,
    String? staffPin,
  }) {
    return AppSettings(
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      storeName: storeName ?? this.storeName,
      masterPin: masterPin ?? this.masterPin,
      staffPin: staffPin ?? this.staffPin,
    );
  }
}

