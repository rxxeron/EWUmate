import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PortalSyncAnnouncementBanner extends StatelessWidget {
  const PortalSyncAnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showPortalSyncAnnouncementModal(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A192F), Color(0xFF0D2342)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0x3319D9F5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF19D9F5).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Glowing cyan circular icon container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF19D9F5).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFF19D9F5).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: Color(0xFF19D9F5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'New Feature in EWUMate?',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Connect your Direct Portal',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Click on the banner! >',
                        style: TextStyle(
                          color: Color(0xFF19D9F5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF19D9F5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showPortalSyncAnnouncementModal(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'PortalSyncAnnouncement',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, anim1, anim2, child) {
      final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOut);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(curve),
        child: FadeTransition(
          opacity: curve,
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1B32),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0x3319D9F5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button top right
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    ),
                  ),
                ),
                // Glowing cyan sync icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF19D9F5).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFF19D9F5).withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF19D9F5).withValues(alpha: 0.25),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    color: Color(0xFF19D9F5),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                // Title
                const Text(
                  'New Feature: EWU Portal Sync',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'Connect your student portal once to automatically pull your registered course routine, faculty info, academic history, and letter grades directly into EWUMate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                // Feature bullets
                _buildFeatureBullet(Icons.calendar_today_rounded, 'Weekly routine & faculty auto synced'),
                const SizedBox(height: 8),
                _buildFeatureBullet(Icons.bar_chart_rounded, 'Complete academic history import'),
                const SizedBox(height: 8),
                _buildFeatureBullet(Icons.verified_user_rounded, '100% Private: Credentials never stored'),
                const SizedBox(height: 24),
                // Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Maybe Later',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/portal-sync');
                        },
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF19D9F5),
                            borderRadius: BorderRadius.circular(23),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF19D9F5).withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Sync Now',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              color: Color(0xFF071426),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildFeatureBullet(IconData icon, String label) {
  return Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF19D9F5)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
