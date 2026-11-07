class SchemeNudge {
  final bool hasScheme;
  final int thresholdQuantity; // e.g. 20 for "20+1" or "20 Bags + 1 Free"
  final int earnedFreeUnits;
  final int unitsNeededForNext;
  final int nextFreeUnits;
  final String message;
  final bool isQualified;
  final double effectivePtr;
  final double effectiveMarginPercent;
  final double baseMarginPercent;

  const SchemeNudge({
    required this.hasScheme,
    this.thresholdQuantity = 0,
    this.earnedFreeUnits = 0,
    this.unitsNeededForNext = 0,
    this.nextFreeUnits = 0,
    this.message = '',
    this.isQualified = false,
    this.effectivePtr = 0.0,
    this.effectiveMarginPercent = 0.0,
    this.baseMarginPercent = 0.0,
  });

  bool get hasBoostedMargin => isQualified && effectiveMarginPercent > baseMarginPercent;
}

class SchemeHelper {
  /// Extracts the minimum trigger threshold integer from a scheme string.
  /// (e.g., "20+1" -> 20, "10:2%" -> 10, "Buy 24 Get 1" -> 24)
  static int parseThreshold(String scheme) {
    if (scheme.trim().isEmpty) return 0;
    final trimmed = scheme.trim();

    // 1. "X+Y" pattern (e.g., "20+1", "10+1 Free", "20 Bags + 1 Free")
    final plusMatch = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(trimmed);
    if (plusMatch != null) {
      return int.tryParse(plusMatch.group(1) ?? '0') ?? 0;
    }

    // 2. "X:Y" pattern (e.g., "10:2%", "10:2")
    final colonMatch = RegExp(r'(\d+)\s*:\s*(\d+)').firstMatch(trimmed);
    if (colonMatch != null) {
      return int.tryParse(colonMatch.group(1) ?? '0') ?? 0;
    }

    // 3. "Buy X Get Y" pattern
    final buyMatch = RegExp(r'(?:buy|order|min)\s*(\d+)', caseSensitive: false).firstMatch(trimmed);
    if (buyMatch != null) {
      return int.tryParse(buyMatch.group(1) ?? '0') ?? 0;
    }

    // 4. Any standalone leading number
    final numMatch = RegExp(r'^(\d+)').firstMatch(trimmed);
    if (numMatch != null) {
      return int.tryParse(numMatch.group(1) ?? '0') ?? 0;
    }

    return 0;
  }

  /// Calculates progressive scheme distance micro-copy, earned bonus units,
  /// effective unit rates, and boosted margin percentages.
  static SchemeNudge calculateNudge({
    required String scheme,
    required int currentQuantity,
    double ptr = 0.0,
    double mrp = 0.0,
  }) {
    if (scheme.trim().isEmpty) {
      return const SchemeNudge(hasScheme: false);
    }

    final trimmed = scheme.trim();
    final baseMargin = (mrp > 0 && ptr > 0) ? ((mrp - ptr) / mrp) * 100 : 0.0;
    final threshold = parseThreshold(trimmed);

    // Check for "X+Y" Free Goods pattern
    final plusMatch = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(trimmed);
    if (plusMatch != null) {
      final buyX = int.tryParse(plusMatch.group(1) ?? '0') ?? 0;
      final freeY = int.tryParse(plusMatch.group(2) ?? '0') ?? 0;

      if (buyX > 0 && freeY > 0) {
        if (currentQuantity <= 0) {
          // Preview state before adding to cart
          return SchemeNudge(
            hasScheme: true,
            thresholdQuantity: buyX,
            nextFreeUnits: freeY,
            unitsNeededForNext: buyX,
            message: 'Buy $buyX, unlock +$freeY Free',
            baseMarginPercent: baseMargin,
            effectiveMarginPercent: baseMargin,
            effectivePtr: ptr,
          );
        }

        final cycles = currentQuantity ~/ buyX;
        final remainder = currentQuantity % buyX;
        final earnedFree = cycles * freeY;
        final neededForNext = buyX - remainder;

        if (cycles == 0) {
          // Below qualifying tier
          return SchemeNudge(
            hasScheme: true,
            thresholdQuantity: buyX,
            earnedFreeUnits: 0,
            unitsNeededForNext: neededForNext,
            nextFreeUnits: freeY,
            isQualified: false,
            message: 'Add $neededForNext more to unlock +$freeY Free ${freeY == 1 ? 'Unit' : 'Units'}',
            baseMarginPercent: baseMargin,
            effectiveMarginPercent: baseMargin,
            effectivePtr: ptr,
          );
        } else {
          // Threshold reached or exceeded
          final totalUnitsReceived = currentQuantity + earnedFree;
          final totalBilledCost = currentQuantity * ptr;
          final effPtr = totalUnitsReceived > 0 ? (totalBilledCost / totalUnitsReceived) : ptr;
          final effMargin = (mrp > 0) ? ((mrp - effPtr) / mrp) * 100 : baseMargin;
          final appliedThreshold = cycles * buyX;

          return SchemeNudge(
            hasScheme: true,
            thresholdQuantity: buyX,
            earnedFreeUnits: earnedFree,
            unitsNeededForNext: remainder == 0 ? buyX : neededForNext,
            nextFreeUnits: freeY,
            isQualified: true,
            message: '✓ Active Scheme: $appliedThreshold + $earnedFree Free Applied',
            baseMarginPercent: baseMargin,
            effectiveMarginPercent: effMargin,
            effectivePtr: effPtr,
          );
        }
      }
    }

    // Cash discount schemes (e.g., "5% CD", "10:2%")
    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(trimmed);
    if (percentMatch != null) {
      final pct = double.tryParse(percentMatch.group(1) ?? '0') ?? 0.0;
      final isQual = threshold <= 0 || currentQuantity >= threshold;
      final effPtr = isQual ? (ptr * (1.0 - (pct / 100.0))) : ptr;
      final effMargin = (mrp > 0) ? ((mrp - effPtr) / mrp) * 100 : baseMargin;

      if (!isQual && currentQuantity > 0) {
        final needed = threshold - currentQuantity;
        return SchemeNudge(
          hasScheme: true,
          thresholdQuantity: threshold,
          unitsNeededForNext: needed,
          isQualified: false,
          message: 'Add $needed more to unlock $pct% Discount',
          baseMarginPercent: baseMargin,
          effectiveMarginPercent: baseMargin,
          effectivePtr: ptr,
        );
      }

      return SchemeNudge(
        hasScheme: true,
        thresholdQuantity: threshold,
        isQualified: isQual,
        message: isQual ? '✓ Active Scheme: $pct% Discount Applied' : 'Scheme: $trimmed',
        baseMarginPercent: baseMargin,
        effectiveMarginPercent: effMargin,
        effectivePtr: effPtr,
      );
    }

    return SchemeNudge(
      hasScheme: true,
      thresholdQuantity: threshold,
      isQualified: currentQuantity > 0,
      message: 'Active Scheme: $trimmed',
      baseMarginPercent: baseMargin,
      effectiveMarginPercent: baseMargin,
      effectivePtr: ptr,
    );
  }
}
