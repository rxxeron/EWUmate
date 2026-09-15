import 'package:flutter/material.dart';

class AdvisingLockedView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AdvisingLockedView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_clock,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.cyan.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
