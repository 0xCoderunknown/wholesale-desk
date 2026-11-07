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
        border: Border.all(
          color: AppTheme.slate300,
          width: 0.8,
        ),
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
