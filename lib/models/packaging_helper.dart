/// Pure domain model and helper for physical packaging & warehouse carton calculations.
/// Computes full boxes and loose units with standard trade nomenclature.
class BoxBreakdown {
  final int totalUnits;
  final int boxSize;
  final int fullBoxes;
  final int looseUnits;
  final int boxedUnits;

  const BoxBreakdown({
    required this.totalUnits,
    required this.boxSize,
    required this.fullBoxes,
    required this.looseUnits,
    required this.boxedUnits,
  });

  bool get hasBoxes => fullBoxes > 0;
  bool get hasLoose => looseUnits > 0;

  /// Packaging trade nomenclature display (e.g. "12 Loose", "1 Box", "1 Box + 4 Loose")
  String get tradeNomenclature {
    if (boxSize <= 0) return '$totalUnits Loose';
    if (fullBoxes == 0) return '$looseUnits Loose';
    final boxText = '$fullBoxes ${fullBoxes == 1 ? 'Box' : 'Boxes'}';
    if (looseUnits == 0) return boxText;
    return '$boxText + $looseUnits Loose';
  }

  /// Dispatch godown breakdown summary (e.g. "📦 2 Full Boxes (48 pcs)  +  🧴 4 Loose Pieces")
  String get dispatchSummary {
    if (fullBoxes > 0 && looseUnits > 0) {
      final boxWord = fullBoxes == 1 ? 'Box' : 'Boxes';
      return '📦 $fullBoxes Full $boxWord ($boxedUnits pcs)  +  🧴 $looseUnits Loose Pieces';
    } else if (fullBoxes > 0) {
      final boxWord = fullBoxes == 1 ? 'Box' : 'Boxes';
      return '📦 $fullBoxes Full $boxWord ($boxedUnits pcs) — Zero Loose Units';
    } else {
      return '🧴 $looseUnits Loose Pieces (Less than 1 full carton)';
    }
  }
}

class PackagingHelper {
  /// Computes carton breakdown given a total quantity and carton packing size.
  static BoxBreakdown calculate({
    required int quantity,
    required int cartonPack,
  }) {
    if (cartonPack <= 0) {
      return BoxBreakdown(
        totalUnits: quantity,
        boxSize: 0,
        fullBoxes: 0,
        looseUnits: quantity,
        boxedUnits: 0,
      );
    }

    final fullBoxes = quantity ~/ cartonPack;
    final looseUnits = quantity % cartonPack;
    final boxedUnits = fullBoxes * cartonPack;

    return BoxBreakdown(
      totalUnits: quantity,
      boxSize: cartonPack,
      fullBoxes: fullBoxes,
      looseUnits: looseUnits,
      boxedUnits: boxedUnits,
    );
  }
}

