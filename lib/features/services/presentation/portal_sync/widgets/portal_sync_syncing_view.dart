import 'package:flutter/material.dart';

class PortalSyncSyncingView extends StatelessWidget {
  final Animation<double> rotationAnimation;
  final int syncChecklistProgress;

  const PortalSyncSyncingView({
    super.key,
    required this.rotationAnimation,
    required this.syncChecklistProgress,
  });

  @override
  Widget build(BuildContext context) {
    final syncSteps = [
      "Saving course routine",
      "Updating faculty information",
      "Storing room details",
      "Importing academic history",
      "Finalizing calculations...",
    ];

    return Padding(
      key: const ValueKey('syncing'),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const Spacer(),
          // Rotating Cyan Sync Icon
          RotationTransition(
            turns: rotationAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF19D9F5).withValues(alpha: 0.12),
                border: Border.all(color: const Color(0xFF19D9F5), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF19D9F5).withValues(alpha: 0.3),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sync_rounded,
                color: Color(0xFF19D9F5),
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Syncing Your Data",
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please wait while we update your EWUMate account.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 36),

          // Database checklist
          ...List.generate(syncSteps.length, (idx) {
            final isDone = syncChecklistProgress > idx + 1;
            final isCurrent = syncChecklistProgress == idx + 1;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  if (isDone)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                      child: const Icon(Icons.check, color: Color(0xFF071426), size: 14),
                    )
                  else if (isCurrent)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF19D9F5),
                      ),
                    )
                  else
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      syncSteps[idx],
                      style: TextStyle(
                        color: isDone ? Colors.white : (isCurrent ? const Color(0xFF19D9F5) : Colors.white38),
                        fontSize: 13.5,
                        fontWeight: isCurrent || isDone ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Spacer(),
          Text(
            "$syncChecklistProgress / ${syncSteps.length}",
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
