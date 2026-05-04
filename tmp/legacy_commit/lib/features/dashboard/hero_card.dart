import 'package:flutter/material.dart';
import '../../core/widgets/glass_kit.dart';

class HeroCard extends StatelessWidget {
  final dynamic iconInfo;
  final String title;
  final String subtitle;
  final Color color;
  final bool iconMode;

  const HeroCard({
    super.key,
    required this.iconInfo,
    required this.title,
    required this.subtitle,
    required this.color,
    this.iconMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      opacity: 0.1,
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        children: [
          if (iconMode)
            Icon(
              iconInfo as IconData,
              size: 40,
              color: color.withValues(alpha: 0.8),
            )
          else
            Text(iconInfo as String, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
