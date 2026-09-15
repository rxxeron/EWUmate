import 'package:flutter/material.dart';
import '../../../../../core/widgets/glass_kit.dart';

class NextSemDraftCard extends StatelessWidget {
  final String nextSemCode;
  final VoidCallback onManualEntry;
  final VoidCallback onDiscard;
  final VoidCallback onUseDraft;

  const NextSemDraftCard({
    super.key,
    required this.nextSemCode,
    required this.onManualEntry,
    required this.onDiscard,
    required this.onUseDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Colors.cyan,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Draft Found!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  nextSemCode,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'We found a saved draft for your upcoming semester.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onManualEntry,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text(
                      'Manual Entry',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDiscard,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text(
                      'Discard',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onUseDraft,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.cyan,
                    ),
                    child: const Text(
                      'Use Draft',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
