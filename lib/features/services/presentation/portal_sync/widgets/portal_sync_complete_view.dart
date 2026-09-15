import 'package:flutter/material.dart';

class PortalSyncCompleteView extends StatelessWidget {
  final int coursesCount;
  final VoidCallback onGoToDashboard;
  final VoidCallback onSyncAgain;
  final bool wasOnboarding;

  const PortalSyncCompleteView({
    super.key,
    required this.coursesCount,
    required this.onGoToDashboard,
    required this.onSyncAgain,
    this.wasOnboarding = false,
  });

  Widget _buildSyncedRowItem(IconData icon, String title, String badgeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2219D9F5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF19D9F5), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981), width: 0.8),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('sync_complete'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
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
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 58,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            wasOnboarding ? "Onboarding Complete!" : "All Set!",
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            wasOnboarding
                ? "Your profile, academic history, and class schedule are all synced. Welcome to EWUMate!"
                : "Your EWU Portal data has been successfully synchronized.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Circular Gauge Card
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF071426),
              border: Border.all(color: const Color(0xFF19D9F5), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF19D9F5).withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$coursesCount / $coursesCount",
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Courses",
                  style: TextStyle(color: Color(0xFF19D9F5), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Summary Synced Cards
          _buildSyncedRowItem(Icons.calendar_today_rounded, "Course Routine", "Synced"),
          const SizedBox(height: 10),
          _buildSyncedRowItem(Icons.person_rounded, "Faculty Information", "Synced"),
          const SizedBox(height: 10),
          _buildSyncedRowItem(Icons.history_edu_rounded, "Academic History", "Synced"),
          const SizedBox(height: 32),

          // Go to Dashboard Button
          GestureDetector(
            onTap: onGoToDashboard,
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
              child: const Text(
                "Go to Dashboard",
                style: TextStyle(
                  fontFamily: 'Sora',
                  color: Color(0xFF071426),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: onSyncAgain,
            child: const Text(
              "Sync Again",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
