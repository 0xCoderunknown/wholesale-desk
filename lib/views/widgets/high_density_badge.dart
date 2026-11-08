import 'package:flutter/material.dart';

import '../../config/theme.dart';

class SchemeBadge extends StatelessWidget {
  final String scheme;

  const SchemeBadge({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (scheme.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.schemeAmberBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.schemeAmber.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer_rounded,
            size: 11,
            color: AppTheme.schemeAmber,
          ),
          const SizedBox(width: 3),
          Text(
            scheme,
            style: const TextStyle(
              color: AppTheme.schemeAmber,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 1-Tap direct action pill to auto-fill qualifying scheme threshold
class SchemeApplyPill extends StatelessWidget {
  final int threshold;
  final VoidCallback onApply;
  final VoidCallback? onRemove;
  final bool isAlreadyActive;

  const SchemeApplyPill({
    super.key,
    required this.threshold,
    required this.onApply,
    this.onRemove,
    this.isAlreadyActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (threshold <= 0) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAlreadyActive ? (onRemove ?? onApply) : onApply,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isAlreadyActive
                ? const Color(0xFFDC2626) // Crimson Red
                : const Color(0xFF047857), // Emerald Green
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAlreadyActive
                    ? Icons.close_rounded
                    : Icons.bolt_rounded,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 3),
              Text(
                isAlreadyActive ? 'REMOVE' : 'APPLY',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoqBadge extends StatelessWidget {
  final int moq;

  const MoqBadge({super.key, required this.moq});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.slate300, width: 0.8),
      ),
      child: Text(
        'MOQ: $moq',
        style: const TextStyle(
          color: AppTheme.slate700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class BoxPackBadge extends StatelessWidget {
  final int cartonPack;

  const BoxPackBadge({super.key, required this.cartonPack});

  @override
  Widget build(BuildContext context) {
    if (cartonPack <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Blue 50
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF93C5FD), // Blue 300
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_rounded,
            size: 11,
            color: Color(0xFF1D4ED8), // Blue 700
          ),
          const SizedBox(width: 3),
          Text(
            'Box: $cartonPack',
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RouteBadge extends StatelessWidget {
  final String route;

  const RouteBadge({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    if (route.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.alt_route_rounded,
            size: 13,
            color: AppTheme.primaryDark,
          ),
          const SizedBox(width: 4),
          Text(
            route,
            style: const TextStyle(
              color: AppTheme.primaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SchemeNudgePill extends StatelessWidget {
  final String message;
  final bool isQualified;

  const SchemeNudgePill({
    super.key,
    required this.message,
    this.isQualified = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();

    final bgColor = isQualified
        ? const Color(0xFF047857) // High-contrast emerald green 700
        : const Color(0xFFFEF3C7); // Amber 100
    final borderColor = isQualified
        ? const Color(0xFF065F46) // Emerald 800
        : const Color(0xFFFCD34D); // Amber 300
    final textColor = isQualified
        ? Colors.white
        : const Color(0xFF92400E); // Amber 800
    final iconColor = isQualified ? Colors.white : const Color(0xFFB45309);

    final cleanMessage = message.trim().startsWith('✓')
        ? message.trim().replaceFirst(RegExp(r'^✓\s*'), '')
        : message.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isQualified
                ? Icons.check_circle_rounded
                : Icons.tips_and_updates_outlined,
            size: 13,
            color: iconColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              cleanMessage,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic margin pill showing base vs boosted margin when scheme is active
class MarginBoostBadge extends StatelessWidget {
  final double baseMargin;
  final double effectiveMargin;
  final double effectivePtr;
  final bool isBoosted;
  final bool compact;

  const MarginBoostBadge({
    super.key,
    required this.baseMargin,
    required this.effectiveMargin,
    required this.effectivePtr,
    this.isBoosted = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final marginVal = (isBoosted && effectiveMargin > baseMargin)
        ? effectiveMargin
        : baseMargin;
    final marginStr = marginVal % 1 == 0
        ? '${marginVal.toInt()}%'
        : '${marginVal.toStringAsFixed(1)}%';

    if (compact) {
      if (isBoosted && effectiveMargin > baseMargin) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '+$marginStr',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFA7F3D0), width: 0.6),
        ),
        child: Text(
          '+$marginStr',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF166534),
          ),
        ),
      );
    }

    if (isBoosted && effectiveMargin > baseMargin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF059669), // Vibrant emerald green 600
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 11,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                'MARGIN: $marginStr',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7), // Mint / Emerald 100
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.6),
      ),
      child: Text(
        'MARGIN: $marginStr',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF166534), // Emerald 800
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
