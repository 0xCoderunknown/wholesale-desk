import 'package:flutter/material.dart';

class ProductAvatar extends StatelessWidget {
  final String name;
  final String brand;
  final double size;
  final double fontSize;

  const ProductAvatar({
    super.key,
    required this.name,
    required this.brand,
    this.size = 38,
    this.fontSize = 15,
  });

  static const List<Color> _palette = [
    Color(0xFF0F766E), // teal 700
    Color(0xFF0369A1), // sky 700
    Color(0xFF4338CA), // indigo 700
    Color(0xFF6D28D9), // purple 700
    Color(0xFFB45309), // amber 700
    Color(0xFFBE123C), // rose 700
    Color(0xFF15803D), // green 700
    Color(0xFF334155), // slate 700
    Color(0xFFC2410C), // orange 700
  ];

  @override
  Widget build(BuildContext context) {
    final seed = (brand.isNotEmpty ? brand : name).trim();
    final initial = seed.isNotEmpty ? seed[0].toUpperCase() : '?';
    
    // Deterministic color selection based on string hash
    final colorIndex = seed.isEmpty ? 0 : seed.codeUnits.fold(0, (a, b) => a + b) % _palette.length;
    final bgColor = _palette[colorIndex];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size > 48 ? 10 : 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

