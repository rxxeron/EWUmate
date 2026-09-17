import 'package:flutter/material.dart';

class PortalSyncConnectingView extends StatelessWidget {
  final AnimationController pulseController;
  final int fetchChecklistProgress;

  const PortalSyncConnectingView({
    super.key,
    required this.pulseController,
    required this.fetchChecklistProgress,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      "Connecting to portal.ewubd.edu",
      "Authenticating session...",
      "Fetching course routine...",
      "Fetching faculty information...",
      "Preparing preview...",
    ];

    return Padding(
      key: const ValueKey('connecting'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const Spacer(),
          // Concentric Animated Radar with Server Icon
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 1.0 + (pulseController.value * 0.08);
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF071426),
                  border: Border.all(
                    color: const Color(0xFF19D9F5).withValues(alpha: 0.2 + (pulseController.value * 0.3)),
                    width: 2.5 * scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF19D9F5).withValues(alpha: 0.25 * pulseController.value),
                      blurRadius: 30 * scale,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D2342),
                      border: Border.all(color: const Color(0xFF19D9F5), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.dns_rounded,
                      color: Color(0xFF19D9F5),
                      size: 34,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            fetchChecklistProgress <= 1
                ? "Connecting..."
                : (fetchChecklistProgress <= 2
                    ? "Authenticating..."
                    : (fetchChecklistProgress <= 3 ? "Fetching Routine..." : "Fetching Faculty...")),
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Establishing secure connection with EWU Portal",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 36),

          // Real-time Checklist Items
          ...List.generate(steps.length, (idx) {
            final isDone = fetchChecklistProgress > idx + 1;
            final isCurrent = fetchChecklistProgress == idx + 1;

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
                      steps[idx],
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

          // Bottom padlock message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF071426),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, color: Color(0xFF19D9F5), size: 16),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "This may take a few seconds. Please don't close the app.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
