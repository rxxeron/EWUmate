import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/widgets/sky_animation.dart';

/// Card-contained greeting header for EWUMate Dashboard matching User Profile Card
class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String displayName;
  final String? photoUrl;
  final String? email;
  final VoidCallback onAvatarTap;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.displayName,
    this.photoUrl,
    this.email,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ewuColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceNavyBlue.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Avatar with Glowing Cyan Gradient Ring
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryCyan,
                      colors.secondarySoftBlue,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryCyan.withValues(alpha: colors.isDark ? 0.35 : 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.2),
                  child: CircleAvatar(
                    backgroundColor: colors.surfaceNavyBlue,
                    backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: (photoUrl == null || photoUrl!.isEmpty)
                        ? Icon(
                            Icons.person,
                            color: colors.primaryCyan,
                            size: 24,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 2. User Info (Greeting, Name, Email, Active Student Pill)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryText,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text("👋", style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (email != null && email!.isNotEmpty) ? email! : "$greeting,",
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: colors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Active Student Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Active Student",
                          style: GoogleFonts.sora(
                            color: const Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // 3. Time-based Interactive Sky Animation (Sunrise, Noon, Sunset, Night)
            const SkyAnimationWidget(size: 50),
          ],
        ),
      ),
    );
  }
}
