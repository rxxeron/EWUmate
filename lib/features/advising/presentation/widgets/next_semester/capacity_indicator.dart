import 'package:flutter/material.dart';

class CapacityIndicator extends StatelessWidget {
  final String capacity;

  const CapacityIndicator({super.key, required this.capacity});

  @override
  Widget build(BuildContext context) {
    if (capacity.isEmpty || !capacity.contains('/')) {
      return const SizedBox.shrink();
    }
    try {
      final parts = capacity.split('/');
      final enrolled = int.parse(parts[0].trim());
      final total = int.parse(parts[1].trim());
      final bool isFull =
          (total > 0 && enrolled >= total) || (total == 0 && enrolled > 0);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: (isFull ? Colors.redAccent : Colors.cyan).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: (isFull ? Colors.redAccent : Colors.cyan).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          isFull ? 'Full' : '${total - enrolled} Left',
          style: TextStyle(
            color: isFull ? Colors.redAccent : Colors.cyan,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
