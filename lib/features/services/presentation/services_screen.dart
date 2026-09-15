import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ewu_theme_extension.dart';
import '../../../core/widgets/ewumate_app_bar.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/widgets/primitives/ewu_surface_card.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.servicesKey,
          steps: OnboardingSteps.services,
        );
      }
    });

    final colors = context.ewuColors;

    final services = [
      _ServiceItem(
        title: 'Cover Page Generator',
        subtitle: 'Create assignment PDFs',
        icon: Icons.picture_as_pdf_rounded,
        accentColor: colors.primaryCyan,
        route: '/services/cover-page',
      ),
      _ServiceItem(
        title: 'Faculty Directory',
        subtitle: 'Search faculty & emails',
        icon: Icons.people_alt_rounded,
        accentColor: colors.primaryCyan,
        route: '/services/faculty-directory',
      ),
      _ServiceItem(
        title: 'Study Materials Vault',
        subtitle: 'Past papers & notes',
        icon: Icons.folder_special_rounded,
        accentColor: colors.primaryCyan,
        route: '/services/study-vault',
      ),
      _ServiceItem(
        title: 'EWU Portal Sync',
        subtitle: 'Auto-import schedule & grades',
        icon: Icons.cloud_sync_rounded,
        accentColor: colors.primaryCyan,
        route: '/portal-sync',
      ),
      _ServiceItem(
        title: 'Faculty Assignment',
        subtitle: 'Check assigned teachers',
        icon: Icons.assignment_ind_rounded,
        accentColor: colors.primaryCyan,
        route: '/services/faculty-assignment',
      ),
      _ServiceItem(
        title: 'Faculty List (PDF)',
        subtitle: 'Download complete list',
        icon: Icons.description_rounded,
        accentColor: colors.primaryCyan,
        route: '/services/faculty-list',
      ),
    ];

    return FullGradientScaffold(
      appBar: const EWUmateAppBar(
        title: 'Services',
        showMenu: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Utilities',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tools to help you manage courses, documents, and portal data',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.18,
              ),
              itemBuilder: (context, index) {
                final item = services[index];
                return EwuSurfaceCard(
                  onTap: () => context.push(item.route),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: item.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: item.accentColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              size: 20,
                              color: item.accentColor,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: colors.textTertiary,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String route;

  const _ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.route,
  });
}
