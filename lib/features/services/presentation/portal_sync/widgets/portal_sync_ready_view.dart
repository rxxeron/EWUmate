import 'package:flutter/material.dart';

class PortalSyncReadyView extends StatelessWidget {
  final VoidCallback onViewPreview;

  const PortalSyncReadyView({
    super.key,
    required this.onViewPreview,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      "Secure session established",
      "Student verified",
      "Routine fetched",
      "Faculty information fetched",
      "Preview ready",
    ];

    return Padding(
      key: const ValueKey('sync_ready'),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const Spacer(),
          // Big Glowing Green Checkmark Circle
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFF10B981), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 28,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 56,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Sync Ready!",
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your data has been fetched successfully.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 32),

          // All 5 checklist items checked
          ...List.generate(steps.length, (idx) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                    child: const Icon(Icons.check, color: Color(0xFF071426), size: 14),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      steps[idx],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Spacer(),

          // View Preview Button
          GestureDetector(
            onTap: onViewPreview,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF19D9F5),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF19D9F5).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "View Preview",
                    style: TextStyle(
                      fontFamily: 'Sora',
                      color: Color(0xFF071426),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF071426), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
