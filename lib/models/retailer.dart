class Retailer {
  final String id;
  final String storeName;
  final String mobile;
  final String pin;
  final String route;
  final String status; // 'active' | 'suspended'

  const Retailer({
    required this.id,
    required this.storeName,
    required this.mobile,
    required this.pin,
    required this.route,
    this.status = 'active',
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory Retailer.fromMap(String id, Map<String, dynamic> map) {
    return Retailer(
      id: id,
      storeName: map['store_name']?.toString() ?? '',
      mobile: map['mobile']?.toString() ?? '',
      pin: map['pin']?.toString() ?? '',
      route: map['route']?.toString() ?? '',
      status: map['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'store_name': storeName,
      'mobile': mobile,
      'pin': pin,
      'route': route,
      'status': status,
    };
  }

  Retailer copyWith({
    String? id,
    String? storeName,
    String? mobile,
    String? pin,
    String? route,
    String? status,
  }) {
    return Retailer(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      mobile: mobile ?? this.mobile,
      pin: pin ?? this.pin,
      route: route ?? this.route,
      status: status ?? this.status,
    );
  }
}

