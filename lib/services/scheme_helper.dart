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

enum SchemeType {
  freeGoods,
  percentage,
  infoNote,
  none,
}

class SchemeClassification {
  final SchemeType type;
  final String raw;
  final String normalized;
  final int threshold; // X in X+Y
  final int freeUnits; // Y in X+Y
  final double percentDiscount; // N in N%
  final String badgeLabel; // e.g. "25+3 Free 🎁", "5% Off 🏷️", "📢 Diwali Note"
  final String previewDescription; // For dialog preview
  final String? warning; // Warning for unusually large quantities or extreme discounts
  final bool canApply;

  static const none = SchemeClassification(
    type: SchemeType.none,
    raw: '',
    normalized: '',
  );

  const SchemeClassification({
    required this.type,
    this.raw = '',
    this.normalized = '',
    this.threshold = 0,
    this.freeUnits = 0,
    this.percentDiscount = 0.0,
    this.badgeLabel = '',
    this.previewDescription = '',
    this.warning,
    this.canApply = false,
  });

  String get label => previewDescription;
  double get discountPercent => percentDiscount;
}

typedef SchemePreview = SchemeClassification;

class SchemeHelper {
  /// Pre-normalizes a raw scheme string:
  /// - Converts to lowercase.
  /// - Replaces word representations `\bplus\b` and `\band\b` with `+`.
  /// - Strips redundant consecutive whitespace.
  static String normalizeScheme(String scheme) {
    if (scheme.trim().isEmpty) return '';
    return scheme
        .toLowerCase()
        .replaceAll(RegExp(r'\bplus\b', caseSensitive: false), '+')
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), '+')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Classifies scheme into strictly three clean states:
  /// 1. Free Goods (X+Y)
  /// 2. Percentage Discount (N%)
  /// 3. Informational Note (infoNote)
  static SchemeClassification parse(String scheme) {
    final raw = scheme.trim();
    if (raw.isEmpty) {
      return const SchemeClassification(
        type: SchemeType.none,
        raw: '',
        normalized: '',
      );
    }

    final normalized = normalizeScheme(raw);

    // 1. Free Goods: r'(\d+)\s*\+\s*(\d+)'
    final plusMatch = RegExp(r'(\d+)\s*(?:[a-zA-Z]+\s*)?\+\s*(\d+)').firstMatch(normalized);
    if (plusMatch != null) {
      final buyX = int.tryParse(plusMatch.group(1) ?? '0') ?? 0;
      final freeY = int.tryParse(plusMatch.group(2) ?? '0') ?? 0;
      if (buyX > 0 && freeY > 0) {
        String? warning;
        if (buyX > 1000 || freeY > 100) {
          warning = '⚠️ Unusually large scheme ($buyX+$freeY). Verify before saving.';
        } else if (freeY > buyX) {
          warning = '⚠️ Free quantity ($freeY) exceeds billed quantity ($buyX). Verify ratio.';
        }

        return SchemeClassification(
          type: SchemeType.freeGoods,
          raw: raw,
          normalized: normalized,
          threshold: buyX,
          freeUnits: freeY,
          badgeLabel: '$buyX+$freeY Free 🎁',
          previewDescription: '🎁 Free Goods: Earn $freeY free for every $buyX billed',
          warning: warning,
          canApply: true,
        );
      }
    }

    // 2. Percentage Discount: r'(\d+(?:\.\d+)?)\s*%'
    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(normalized);
    if (percentMatch != null) {
      final val = double.tryParse(percentMatch.group(1) ?? '0') ?? 0.0;
      if (val > 0) {
        final formattedVal = val.truncateToDouble() == val ? val.toInt().toString() : val.toString();
        String? warning;
        if (val >= 100.0) {
          warning = '⚠️ Extreme discount: $formattedVal% is 100% or greater! Product rate will become ₹0.';
        } else if (val > 50.0) {
          warning = '⚠️ High discount: $formattedVal% exceeds 50%. Verify distributor margins.';
        }

        return SchemeClassification(
          type: SchemeType.percentage,
          raw: raw,
          normalized: normalized,
          percentDiscount: val,
          badgeLabel: '$formattedVal% Off 🏷️',
          previewDescription: '🏷️ Percentage: $formattedVal% deducted from unit PTR on apply',
          warning: warning,
          canApply: true,
        );
      }
    }

    // 3. Informational Note (matches neither X+Y nor N%)
    // Crucial UI Guard: Do NOT show an [APPLY] button (canApply = false)
    return SchemeClassification(
      type: SchemeType.infoNote,
      raw: raw,
      normalized: normalized,
      badgeLabel: '📢 $raw',
      previewDescription: 'ℹ️ Note: Shown as informational badge (no automated cart math)',
      canApply: false,
    );
  }

  /// Alias for parse
  static SchemeClassification parsePreview(String scheme) => parse(scheme);

  /// Extracts the minimum trigger threshold integer from a scheme string.
  /// - Returns integer for Volume Tier / Free Goods schemes (e.g., "10+1" -> 10, "12+1 Free" -> 12).
  /// - Returns 0 for Percentage Discounts and Informational Notes (handled by product MOQ).
  static int parseThreshold(String scheme) {
    final parsed = parse(scheme);
    if (parsed.type == SchemeType.freeGoods) {
      return parsed.threshold;
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
    final parsed = parse(scheme);
    final baseMargin = (mrp > 0 && ptr > 0) ? ((mrp - ptr) / mrp) * 100 : 0.0;

    if (parsed.type == SchemeType.none || currentQuantity <= 0) {
      return SchemeNudge(
        hasScheme: false,
        message: '',
        isQualified: false,
        baseMarginPercent: baseMargin,
        effectiveMarginPercent: baseMargin,
        effectivePtr: ptr,
      );
    }

    // 1. Percentage Discount:
    if (parsed.type == SchemeType.percentage) {
      final pct = parsed.percentDiscount;
      final effPtr = pct > 0 ? (ptr * (1.0 - (pct / 100.0))) : ptr;
      final effMargin = (mrp > 0) ? ((mrp - effPtr) / mrp) * 100 : baseMargin;

      return SchemeNudge(
        hasScheme: true,
        thresholdQuantity: 0,
        message: '', // Continuous % discount: no micro-copy needed
        isQualified: pct > 0 && currentQuantity > 0,
        baseMarginPercent: baseMargin,
        effectiveMarginPercent: effMargin,
        effectivePtr: effPtr,
      );
    }

    // 2. Free Goods (X+Y):
    if (parsed.type == SchemeType.freeGoods) {
      final buyX = parsed.threshold;
      final freeY = parsed.freeUnits;
      final cycles = currentQuantity ~/ buyX;
      final remainder = currentQuantity % buyX;
      final earnedFree = cycles * freeY;
      final neededForNext = buyX - remainder;

      if (cycles == 0) {
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
          message: 'Scheme Unlocked: $earnedFree Free ${earnedFree == 1 ? 'Unit' : 'Units'} Applied',
          baseMarginPercent: baseMargin,
          effectiveMarginPercent: effMargin,
          effectivePtr: effPtr,
        );
      }
    }

    // Cash Rebate compatibility ("Buy 24 Get ₹100 Off")
    final rebateMatch = RegExp(
      r'(?:buy|order|min)\s*(\d+)\s*(?:get\s*)?(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d+)?)\s*(?:off|cashback|disc)',
      caseSensitive: false,
    ).firstMatch(parsed.normalized);
    if (rebateMatch != null) {
      final buyX = int.tryParse(rebateMatch.group(1) ?? '0') ?? 0;
      final rebateY = double.tryParse(rebateMatch.group(2) ?? '0') ?? 0.0;
      if (buyX > 0 && rebateY > 0) {
        final cycles = currentQuantity ~/ buyX;
        final remainder = currentQuantity % buyX;
        final neededForNext = buyX - remainder;
        final totalRebate = cycles * rebateY;
        final billedCost = (currentQuantity * ptr) - totalRebate;
        final effPtr = currentQuantity > 0 ? (billedCost / currentQuantity) : ptr;
        final effMargin = (mrp > 0) ? ((mrp - effPtr) / mrp) * 100 : baseMargin;

        return SchemeNudge(
          hasScheme: true,
          thresholdQuantity: buyX,
          unitsNeededForNext: remainder == 0 ? buyX : neededForNext,
          isQualified: cycles > 0,
          message: cycles > 0 ? 'Scheme Unlocked: ₹${totalRebate.toStringAsFixed(0)} Off Applied' : '',
          baseMarginPercent: baseMargin,
          effectiveMarginPercent: effMargin,
          effectivePtr: effPtr,
        );
      }
    }

    // 3. Informational Note:
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
    final parsed = parse(scheme);
    if (parsed.type == SchemeType.none || mrp <= 0 || ptr <= 0) {
      return (maxMargin: baseMargin, effPtr: ptr, breakdownCopy: '', threshold: 0);
    }

    // 1. Percentage
    if (parsed.type == SchemeType.percentage) {
      final pct = parsed.percentDiscount;
      final effPtr = ptr * (1.0 - (pct / 100.0));
      final effMargin = ((mrp - effPtr) / mrp) * 100;
      final formattedPct = pct.truncateToDouble() == pct ? pct.toInt().toString() : pct.toString();
      return (
        maxMargin: effMargin,
        effPtr: effPtr,
        breakdownCopy: '$formattedPct% Instant Discount on billed amount',
        threshold: 0,
      );
    }

    // 2. Free Goods
    if (parsed.type == SchemeType.freeGoods) {
      final buyX = parsed.threshold;
      final freeY = parsed.freeUnits;
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

    // 3. Info Note
    return (maxMargin: baseMargin, effPtr: ptr, breakdownCopy: parsed.raw, threshold: 0);
  }

  /// Formats a clean, compact scheme badge string (<= 14 characters)
  /// e.g. "25+3 Free 🎁" or "5% Off 🏷️"
  static String formatCompactBadge(String scheme) {
    final parsed = parse(scheme);
    if (parsed.type == SchemeType.none) return '';
    return parsed.badgeLabel;
  }
}
