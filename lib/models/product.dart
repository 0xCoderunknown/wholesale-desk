class Product {
  final String id;
  final String name;
  final String brand;
  final double mrp;
  final double ptr; // Purchase To Retailer
  final String scheme; // e.g., "10+1", "5% CD", etc.
  final int moq; // Minimum Order Quantity
  final int cartonPack; // Box size / Carton packing (0 if unspecified)
  final bool inStock;
  final String imageUrl; // Kept empty for zero-bloat
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.mrp,
    required this.ptr,
    this.scheme = '',
    this.moq = 1,
    this.cartonPack = 0,
    this.inStock = true,
    this.imageUrl = '',
    this.updatedAt,
  });

  bool get hasCartonPack => cartonPack > 0;
  double get margin => mrp - ptr;
  double get marginPercent => mrp > 0 ? ((mrp - ptr) / mrp) * 100 : 0.0;

  /// Pure domain logic: returns effective minimum order quantity respecting enforceMoq
  int minOrderQuantity({bool enforceMoq = true}) {
    return (enforceMoq && moq > 0) ? moq : 1;
  }

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
    return name.toLowerCase().contains(q) ||
        brand.toLowerCase().contains(q) ||
        scheme.toLowerCase().contains(q);
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    DateTime? updated;
    final rawDate = map['updated_at'];
    if (rawDate is DateTime) {
      updated = rawDate;
    } else if (rawDate is String) {
      updated = DateTime.tryParse(rawDate);
    } else if (rawDate is int) {
      updated = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate != null && rawDate.runtimeType.toString().contains('Timestamp')) {
      // Dynamic duck-typing for Firestore Timestamp without hard SDK coupling
      try {
        updated = (rawDate as dynamic).toDate() as DateTime?;
      } catch (_) {}
    }

    final rawCarton = map['carton_pack'] ?? map['box_size'];
    final carton = (rawCarton is num)
        ? rawCarton.toInt()
        : int.tryParse(rawCarton?.toString() ?? '0') ?? 0;

    return Product(
      id: id,
      name: map['name']?.toString() ?? '',
      brand: map['brand']?.toString() ?? '',
      mrp: (map['mrp'] is num) ? (map['mrp'] as num).toDouble() : double.tryParse(map['mrp']?.toString() ?? '0') ?? 0.0,
      ptr: (map['ptr'] is num) ? (map['ptr'] as num).toDouble() : double.tryParse(map['ptr']?.toString() ?? '0') ?? 0.0,
      scheme: map['scheme']?.toString() ?? map['scheme_shorthand']?.toString() ?? map['scheme_badge']?.toString() ?? '',
      moq: (map['moq'] is num) ? (map['moq'] as num).toInt() : int.tryParse(map['moq']?.toString() ?? '1') ?? 1,
      cartonPack: carton,
      inStock: map['in_stock'] is bool ? map['in_stock'] as bool : true,
      imageUrl: map['image_url']?.toString() ?? '',
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'mrp': mrp,
      'ptr': ptr,
      'scheme': scheme,
      'moq': moq,
      'carton_pack': cartonPack,
      'box_size': cartonPack,
      'in_stock': inStock,
      'image_url': imageUrl,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    double? mrp,
    double? ptr,
    String? scheme,
    int? moq,
    int? cartonPack,
    bool? inStock,
    String? imageUrl,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      mrp: mrp ?? this.mrp,
      ptr: ptr ?? this.ptr,
      scheme: scheme ?? this.scheme,
      moq: moq ?? this.moq,
      cartonPack: cartonPack ?? this.cartonPack,
      inStock: inStock ?? this.inStock,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
