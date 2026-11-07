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
  /// - Returns integer for Volume Tier / Free Goods schemes (e.g., "10+1" -> 10, "12+1 Free" -> 12, "20 Bags + 1 Free" -> 20, "Buy 24 Get ₹100 Off" -> 24).
  /// - Returns 0 for Cash Discounts, Percentages, and Net Rates (e.g. "5% Cash Disc", "3% Special Scheme", "Net Rate") where no discrete threshold exists.
  static int parseThreshold(String scheme) {
    if (scheme.trim().isEmpty) return 0;
    final trimmed = scheme.trim();

    // 1. Percentage discounts or Net Rates apply continuously to any quantity. No discrete auto-fill threshold.
    if (trimmed.contains('%') || trimmed.toLowerCase().contains('net rate')) {
      return 0;
    }

    // 2. "X+Y" pattern (e.g., "10+1", "12+1 Free", "20 Bags + 1 Free", "20+1")
    final plusMatch = RegExp(r'(\d+)\s*(?:[a-zA-Z]+\s*)?\+\s*(\d+)').firstMatch(trimmed);
    if (plusMatch != null) {
      return int.tryParse(plusMatch.group(1) ?? '0') ?? 0;
    }

    // 3. "Buy X Get ..." pattern (e.g. "Buy 24 Get ₹100 Off", "Buy 20 Get 1 Free")
    final buyMatch = RegExp(r'(?:buy|order|min)\s*(\d+)', caseSensitive: false).firstMatch(trimmed);
    if (buyMatch != null) {
      return int.tryParse(buyMatch.group(1) ?? '0') ?? 0;
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

    // Rule: When currentQuantity == 0, completely hide micro-copy!
    if (currentQuantity <= 0) {
      return SchemeNudge(
        hasScheme: false,
        message: '',
        isQualified: false,
        baseMarginPercent: baseMargin,
        effectiveMarginPercent: baseMargin,
        effectivePtr: ptr,
      );
    }

    // Continuous schemes like "5% Cash Disc", "Net Rate":
    // Do NOT display any yellow micro-copy line at any time.
    if (trimmed.contains('%') || trimmed.toLowerCase().contains('net rate')) {
      final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(trimmed);
      final pct = percentMatch != null ? double.tryParse(percentMatch.group(1) ?? '0') ?? 0.0 : 0.0;
      final effPtr = pct > 0 ? (ptr * (1.0 - (pct / 100.0))) : ptr;
      final effMargin = (mrp > 0) ? ((mrp - effPtr) / mrp) * 100 : baseMargin;

      return SchemeNudge(
        hasScheme: true,
        thresholdQuantity: 0,
        message: '', // No micro-copy line for percentage or net rate schemes
        isQualified: pct > 0 && currentQuantity > 0,
        baseMarginPercent: baseMargin,
        effectiveMarginPercent: effMargin,
        effectivePtr: effPtr,
      );
    }

    // Flat Slab Cash Rebate ("Buy 24 Get ₹100 Off" or "Buy 24 Get 100 Off")
    final rebateMatch = RegExp(
      r'(?:buy|order|min)\s*(\d+)\s*(?:get\s*)?(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d+)?)\s*(?:off|cashback|disc)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (rebateMatch != null) {
      final buyX = int.tryParse(rebateMatch.group(1) ?? '0') ?? 0;
      final rebateY = double.tryParse(rebateMatch.group(2) ?? '0') ?? 0.0;

      if (buyX > 0 && rebateY > 0) {
        final cycles = currentQuantity ~/ buyX;
        final remainder = currentQuantity % buyX;
        final neededForNext = buyX - remainder;

        if (cycles == 0) {
          return SchemeNudge(
            hasScheme: true,
            thresholdQuantity: buyX,
            unitsNeededForNext: neededForNext,
            isQualified: false,
            message: 'Add $neededForNext more to unlock ₹${rebateY.toStringAsFixed(0)} Off',
            baseMarginPercent: baseMargin,
            effectiveMarginPercent: baseMargin,
            effectivePtr: ptr,
          );
        } else {
          final totalRebate = cycles * rebateY;
          final billedCost = (currentQuantity * ptr) - totalRebate;
          final effPtr = currentQuantity > 0 ? (billedCost / currentQuantity) : ptr;
          final effMargin = (mrp > 0) ? ((mrp - effPtr) / mrp) * 100 : baseMargin;

          return SchemeNudge(
            hasScheme: true,
            thresholdQuantity: buyX,
            unitsNeededForNext: remainder == 0 ? buyX : neededForNext,
            isQualified: true,
            message: '✓ Scheme Unlocked: ₹${totalRebate.toStringAsFixed(0)} Off Applied',
            baseMarginPercent: baseMargin,
            effectiveMarginPercent: effMargin,
            effectivePtr: effPtr,
          );
        }
      }
    }

    // Volume Tier / Free Goods schemes ("X+Y" or "X Bags + Y")
    final plusMatch = RegExp(r'(\d+)\s*(?:[a-zA-Z]+\s*)?\+\s*(\d+)').firstMatch(trimmed);
    if (plusMatch != null) {
      final buyX = int.tryParse(plusMatch.group(1) ?? '0') ?? 0;
      final freeY = int.tryParse(plusMatch.group(2) ?? '0') ?? 0;

      if (buyX > 0 && freeY > 0) {
        final cycles = currentQuantity ~/ buyX;
        final remainder = currentQuantity % buyX;
        final earnedFree = cycles * freeY;
        final neededForNext = buyX - remainder;

        if (cycles == 0) {
          // Below qualifying tier:
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
          // Threshold reached or exceeded:
          final totalUnitsReceived = currentQuantity + earnedFree;
          final totalBilledCost = currentQuantity * ptr;
          final effPtr = totalUnitsReceived > 0 ? (totalBilledCost / totalUnitsReceived) : ptr;
          final effMargin = (mrp > 0) ? ((mrp - effPtr) / mrp) * 100 : baseMargin;

          return SchemeNudge(
            hasScheme: true,
            thresholdQuantity: buyX,
            earnedFreeUnits: earnedFree,
            unitsNeededForNext: remainder == 0 ? buyX : neededForNext,
            nextFreeUnits: freeY,
            isQualified: true,
            message: '✓ Scheme Unlocked: $earnedFree Free ${earnedFree == 1 ? 'Unit' : 'Units'} Applied',
            baseMarginPercent: baseMargin,
            effectiveMarginPercent: effMargin,
            effectivePtr: effPtr,
          );
        }
      }
    }

    return SchemeNudge(
      hasScheme: true,
      thresholdQuantity: 0,
      isQualified: false,
      message: '',
      baseMarginPercent: baseMargin,
      effectiveMarginPercent: baseMargin,
      effectivePtr: ptr,
    );
  }

  /// Computes the maximum potential effective margin, effective PTR,
  /// and itemized breakdown description when a scheme threshold is satisfied.
  static ({double maxMargin, double effPtr, String breakdownCopy, int threshold}) getMaxSchemeDetails({
    required String scheme,
    required double ptr,
    required double mrp,
  }) {
    final baseMargin = (mrp > 0 && ptr > 0) ? ((mrp - ptr) / mrp) * 100 : 0.0;
    if (scheme.trim().isEmpty || mrp <= 0 || ptr <= 0) {
      return (maxMargin: baseMargin, effPtr: ptr, breakdownCopy: '', threshold: 0);
    }

    final trimmed = scheme.trim();

    // 1. Percentage / Cash Discount ("5% Cash Disc")
    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(trimmed);
    if (percentMatch != null) {
      final pct = double.tryParse(percentMatch.group(1) ?? '0') ?? 0.0;
      if (pct > 0) {
        final effPtr = ptr * (1.0 - (pct / 100.0));
        final effMargin = ((mrp - effPtr) / mrp) * 100;
        return (
          maxMargin: effMargin,
          effPtr: effPtr,
          breakdownCopy: '$pct% Instant Cash Discount on billed amount',
          threshold: 0,
        );
      }
    }

    // 2. Free Goods ("12+1 Free" or "20 Bags + 1 Free")
    final plusMatch = RegExp(r'(\d+)\s*(?:[a-zA-Z]+\s*)?\+\s*(\d+)').firstMatch(trimmed);
    if (plusMatch != null) {
      final buyX = int.tryParse(plusMatch.group(1) ?? '0') ?? 0;
      final freeY = int.tryParse(plusMatch.group(2) ?? '0') ?? 0;
      if (buyX > 0 && freeY > 0) {
        final totalUnits = buyX + freeY;
        final effPtr = (buyX * ptr) / totalUnits;
        final effMargin = ((mrp - effPtr) / mrp) * 100;
        return (
          maxMargin: effMargin,
          effPtr: effPtr,
          breakdownCopy: 'Buy $buyX units → Get $freeY ${freeY == 1 ? 'unit' : 'units'} FREE',
          threshold: buyX,
        );
      }
    }

    // 3. Flat Slab Cash Rebate ("Buy 24 Get ₹100 Off")
    final rebateMatch = RegExp(
      r'(?:buy|order|min)\s*(\d+)\s*(?:get\s*)?(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d+)?)\s*(?:off|cashback|disc)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (rebateMatch != null) {
      final buyX = int.tryParse(rebateMatch.group(1) ?? '0') ?? 0;
      final rebateY = double.tryParse(rebateMatch.group(2) ?? '0') ?? 0.0;
      if (buyX > 0 && rebateY > 0) {
        final effPtr = ((buyX * ptr) - rebateY) / buyX;
        final effMargin = ((mrp - effPtr) / mrp) * 100;
        return (
          maxMargin: effMargin,
          effPtr: effPtr,
          breakdownCopy: 'Buy $buyX units → Get ₹${rebateY.toStringAsFixed(0)} instant rebate',
          threshold: buyX,
        );
      }
    }

    return (maxMargin: baseMargin, effPtr: ptr, breakdownCopy: '', threshold: 0);
  }
}
