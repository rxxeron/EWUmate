import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_kit.dart';
import '../../../core/widgets/onboarding_overlay.dart';
import '../../../core/constants/onboarding_steps.dart';
import '../data/tutorial_model.dart';
import '../data/tutorials_repository.dart';

final _tutorialsProvider = FutureProvider<List<Tutorial>>((ref) {
  return ref.read(tutorialsRepositoryProvider).fetchAll();
});

class TutorialsScreen extends ConsumerWidget {
  const TutorialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        OnboardingOverlay.show(
          context: context,
          featureKey: OnboardingSteps.tutorialsKey,
          steps: OnboardingSteps.tutorials,
        );
      }
    });

    final tutorialsAsync = ref.watch(_tutorialsProvider);
    return FullGradientScaffold(
      appBar: AppBar(
        title: Text(
          'Video Tutorials',
          style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Replay Welcome Tour',
            icon: const Icon(Icons.auto_stories_rounded, color: AppColors.primaryCyan, size: 22),
            onPressed: () => context.push('/onboarding/welcome-tour'),
          ),
        ],
      ),
      body: tutorialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load tutorials',
                style: GoogleFonts.sora(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.refresh(_tutorialsProvider),
                child: Text(
                  'Retry',
                  style: GoogleFonts.sora(color: AppColors.primaryCyan, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        data: (tutorials) => _TutorialsContent(tutorials: tutorials, ref: ref),
      ),
    );
  }
}

class _TutorialsContent extends StatelessWidget {
  final List<Tutorial> tutorials;
  final WidgetRef ref;

  const _TutorialsContent({required this.tutorials, required this.ref});

  Future<void> _launchVideo(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final featured = tutorials.where((t) => t.isFeatured).firstOrNull;
    final rest = tutorials.where((t) => !t.isFeatured).toList();
    final Map<String, List<Tutorial>> grouped = {};
    for (final t in rest) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(_tutorialsProvider),
      color: Colors.cyanAccent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (featured != null) ...
            [
              _FeaturedVideoCard(
                tutorial: featured,
                onTap: () => _launchVideo(context, featured.youtubeUrl),
              ),
              const SizedBox(height: 28),
            ],
          if (tutorials.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No tutorials available yet.\nCheck back soon!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.6),
                ),
              ),
            ),
          ...grouped.entries.map(
            (entry) => _CategorySection(
              category: entry.key,
              tutorials: entry.value,
              onTap: (url) => _launchVideo(context, url),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedVideoCard extends StatelessWidget {
  final Tutorial tutorial;
  final VoidCallback onTap;

  const _FeaturedVideoCard({required this.tutorial, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FEATURED',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: tutorial.resolvedThumbnail.isNotEmpty
                        ? Image.network(
                            tutorial.resolvedThumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Icon(Icons.video_library_rounded,
                                  color: Colors.white24, size: 60),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1E293B),
                            child: const Icon(Icons.video_library_rounded,
                                color: Colors.white24, size: 60),
                          ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.black, size: 36),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        tutorial.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (tutorial.description != null && tutorial.description!.isNotEmpty) ...
          [
            const SizedBox(height: 10),
            Text(
              tutorial.description!,
              style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
          ],
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<Tutorial> tutorials;
  final void Function(String url) onTap;

  const _CategorySection({
    required this.category,
    required this.tutorials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        ...tutorials.map((t) => _VideoCard(
              tutorial: t,
              onTap: () => onTap(t.youtubeUrl),
            )),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Tutorial tutorial;
  final VoidCallback onTap;

  const _VideoCard({required this.tutorial, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    tutorial.resolvedThumbnail.isNotEmpty
                        ? Image.network(
                            tutorial.resolvedThumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF0F172A),
                              child: const Icon(Icons.play_circle_outline,
                                  color: Colors.white24, size: 28),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF0F172A),
                            child: const Icon(Icons.play_circle_outline,
                                color: Colors.white24, size: 28),
                          ),
                    Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorial.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tutorial.description != null &&
                        tutorial.description!.isNotEmpty) ...
                      [
                        const SizedBox(height: 4),
                        Text(
                          tutorial.description!,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11, height: 1.4),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        tutorial.category,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
