import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';

/// Sky phase types representing day cycles matching user-provided animations
enum SkyPhase {
  sunrise,
  sunny,
  night,
}

/// Time-based interactive sky animation widget powered by user-provided Lottie animations
class SkyAnimationWidget extends StatefulWidget {
  final SkyPhase? initialPhase;
  final ValueChanged<SkyPhase>? onPhaseChanged;
  final double size;

  const SkyAnimationWidget({
    super.key,
    this.initialPhase,
    this.onPhaseChanged,
    this.size = 52,
  });

  @override
  State<SkyAnimationWidget> createState() => _SkyAnimationWidgetState();
}

class _SkyAnimationWidgetState extends State<SkyAnimationWidget> {
  late SkyPhase _currentPhase;

  @override
  void initState() {
    super.initState();
    _currentPhase = widget.initialPhase ?? _detectPhaseFromTime();
  }

  SkyPhase _detectPhaseFromTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return SkyPhase.sunrise;
    if (hour >= 12 && hour < 18) return SkyPhase.sunny;
    return SkyPhase.night;
  }

  void _cycleNextPhase() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_currentPhase) {
        case SkyPhase.sunrise:
          _currentPhase = SkyPhase.sunny;
          break;
        case SkyPhase.sunny:
          _currentPhase = SkyPhase.night;
          break;
        case SkyPhase.night:
          _currentPhase = SkyPhase.sunrise;
          break;
      }
    });
    widget.onPhaseChanged?.call(_currentPhase);

    // Show feedback toast
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _phaseIcon(_currentPhase),
                color: AppColors.primaryCyan,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Sky View: ${_phaseName(_currentPhase)}',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF09182D),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
        ),
      );
    }
  }

  IconData _phaseIcon(SkyPhase phase) {
    switch (phase) {
      case SkyPhase.sunrise:
        return Icons.wb_twilight_rounded;
      case SkyPhase.sunny:
        return Icons.wb_sunny_rounded;
      case SkyPhase.night:
        return Icons.nightlight_round;
    }
  }

  String _phaseName(SkyPhase phase) {
    switch (phase) {
      case SkyPhase.sunrise:
        return 'Sunrise 🌅';
      case SkyPhase.sunny:
        return 'Sunny Day ☀️';
      case SkyPhase.night:
        return 'Night Sky 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _cycleNextPhase,
      child: Tooltip(
        message: '${_phaseName(_currentPhase)} (Tap to switch)',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getSkyGradient(_currentPhase),
            border: Border.all(
              color: _getBorderColor(_currentPhase),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getShadowColor(_currentPhase),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(_currentPhase),
                child: _buildLottiePhase(_currentPhase),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLottiePhase(SkyPhase phase) {
    final String primaryPath = switch (phase) {
      SkyPhase.sunrise => 'Lottiejson/Sunrise.json',
      SkyPhase.sunny => 'Lottiejson/sunny.json',
      SkyPhase.night => 'Lottiejson/night.json',
    };
    final String fallbackPath = switch (phase) {
      SkyPhase.sunrise => 'assets/lottie/sunrise.json',
      SkyPhase.sunny => 'assets/lottie/sunny.json',
      SkyPhase.night => 'assets/lottie/night.json',
    };

    final BoxFit fit = switch (phase) {
      SkyPhase.sunrise => BoxFit.contain,
      SkyPhase.sunny => BoxFit.cover,
      SkyPhase.night => BoxFit.cover,
    };

    final EdgeInsets padding = switch (phase) {
      SkyPhase.sunrise => const EdgeInsets.all(2.0),
      SkyPhase.sunny => EdgeInsets.zero,
      SkyPhase.night => EdgeInsets.zero,
    };

    return Padding(
      padding: padding,
      child: Lottie.asset(
        primaryPath,
        fit: fit,
        animate: true,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to assets/lottie copy or icon scene
          return Lottie.asset(
            fallbackPath,
            fit: fit,
            animate: true,
            repeat: true,
            errorBuilder: (_, __, ___) => _buildFallbackScene(phase),
          );
        },
      ),
    );
  }

  LinearGradient _getSkyGradient(SkyPhase phase) {
    switch (phase) {
      case SkyPhase.sunrise:
        return const LinearGradient(
          colors: [
            Color(0xFF2E1C4E),
            Color(0xFFFF5E62),
            Color(0xFFFFB47B),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        );
      case SkyPhase.sunny:
        return const LinearGradient(
          colors: [
            Color(0xFF0F4C81),
            Color(0xFF1E88E5),
            Color(0xFF81D4FA),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
      case SkyPhase.night:
        return const LinearGradient(
          colors: [
            Color(0xFF070B14),
            Color(0xFF0F1B2E),
            Color(0xFF1E2D4A),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
    }
  }

  Color _getBorderColor(SkyPhase phase) {
    switch (phase) {
      case SkyPhase.sunrise:
        return const Color(0xFFFFB47B).withValues(alpha: 0.55);
      case SkyPhase.sunny:
        return AppColors.primaryCyan.withValues(alpha: 0.55);
      case SkyPhase.night:
        return const Color(0xFF64B5F6).withValues(alpha: 0.35);
    }
  }

  Color _getShadowColor(SkyPhase phase) {
    switch (phase) {
      case SkyPhase.sunrise:
        return const Color(0xFFFF5E62).withValues(alpha: 0.35);
      case SkyPhase.sunny:
        return const Color(0xFF1E88E5).withValues(alpha: 0.35);
      case SkyPhase.night:
        return const Color(0xFF070B14).withValues(alpha: 0.5);
    }
  }

  Widget _buildFallbackScene(SkyPhase phase) {
    final IconData icon = _phaseIcon(phase);
    final Color color = switch (phase) {
      SkyPhase.sunrise => const Color(0xFFFFD166),
      SkyPhase.sunny => const Color(0xFFFFF176),
      SkyPhase.night => const Color(0xFF90CAF9),
    };

    return Center(
      child: Icon(icon, color: color, size: widget.size * 0.5),
    );
  }
}
