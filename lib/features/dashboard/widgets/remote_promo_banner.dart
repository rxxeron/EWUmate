import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../core/providers/feature_flag_provider.dart';
import '../../../core/theme/app_colors.dart';

class RemotePromoBanner extends ConsumerStatefulWidget {
  const RemotePromoBanner({super.key});

  @override
  ConsumerState<RemotePromoBanner> createState() => _RemotePromoBannerState();
}

class _RemotePromoBannerState extends ConsumerState<RemotePromoBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final bannerAsync = ref.watch(promoBannerProvider);
    return bannerAsync.maybeWhen(
      data: (config) {
        if (config == null) return const SizedBox.shrink();
        final isActive = config['is_active'] == true || config['enabled'] == true;
        if (!isActive) return const SizedBox.shrink();

        final imageUrl = config['image_url']?.toString() ?? '';
        final linkUrl = (config['link_url'] ?? config['link'])?.toString() ?? '';
        if (imageUrl.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Stack(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: linkUrl.isNotEmpty
                          ? () async {
                              if (linkUrl.startsWith('/')) {
                                context.push(linkUrl);
                                return;
                              }
                              final uri = Uri.tryParse(linkUrl);
                              if (uri != null) {
                                if (uri.scheme == 'http' || uri.scheme == 'https') {
                                  await url_launcher.launchUrl(
                                    uri,
                                    mode: url_launcher.LaunchMode.externalApplication,
                                  );
                                } else {
                                  context.push(linkUrl);
                                }
                              }
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                            placeholder: (context, url) => Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryCyan,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Dismiss button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _isDismissed = true),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
