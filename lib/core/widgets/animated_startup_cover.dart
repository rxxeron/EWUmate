import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Elevated animated startup cover strictly following the timeline from
/// `WhatsApp Image 2026-09-12 at 15.19.34.jpeg`:
///
/// 0.0s: Dark Screen
/// 0.2s: Cyan Glow Appears
/// 0.4s: E / Book Forms
/// 0.6s: Graduation Cap Slides In
/// 0.8s: Tassel Swings
/// 1.0s: App Name Appears
/// 1.2s: Tagline Appears
/// 1.5s+: Smooth Ambient Breathing & Dashboard Readiness
class AnimatedStartupCover extends StatefulWidget {
  final String statusText;
  final Widget? trailing;

  const AnimatedStartupCover({
    super.key,
    this.statusText = 'Syncing universe...',
    this.trailing,
  });

  @override
  State<AnimatedStartupCover> createState() => _AnimatedStartupCoverState();
}

class _AnimatedStartupCoverState extends State<AnimatedStartupCover>
    with TickerProviderStateMixin {
  // Sequence intro controller (0.0s to 1.5s)
  late final AnimationController _introController;

  // Staged intro animations
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _capSlideY;
  late final Animation<double> _tasselSwing;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _statusOpacity;

  // Continuous ambient breathing controller
  late final AnimationController _ambientController;
  late final Animation<double> _ambientGlow;
  late final Animation<double> _ambientScale;
  late final Animation<double> _ambientSheen;

  @override
  void initState() {
    super.initState();

    // 1. Intro sequence (1500 ms)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 0.2s (t = 0.13 to 0.40): Cyan Glow Appears
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.13, 0.40, curve: Curves.easeOut),
      ),
    );
    _glowScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.13, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // 0.4s (t = 0.26 to 0.55): E / Book Base Forms
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.26, 0.55, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.26, 0.60, curve: Curves.easeOutBack),
      ),
    );

    // 0.6s (t = 0.40 to 0.68): Graduation Cap slides down
    _capSlideY = Tween<double>(begin: -18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.40, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // 0.8s (t = 0.53 to 0.80): Tassel swings gently
    _tasselSwing = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.08), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.08, end: -0.06), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: -0.06, end: 0.0), weight: 35),
    ]).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.53, 0.80, curve: Curves.easeInOut),
      ),
    );

    // 1.0s (t = 0.66 to 0.88): App Name Appears
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.66, 0.88, curve: Curves.easeOut),
      ),
    );
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.66, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // 1.2s (t = 0.80 to 1.0): Tagline Appears
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Status bar fades in with name
    _statusOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.70, 0.95, curve: Curves.easeOut),
      ),
    );

    // 2. Continuous Ambient Controller
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _ambientGlow = Tween<double>(begin: 0.40, end: 0.85).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _ambientScale = Tween<double>(begin: 0.985, end: 1.025).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _ambientSheen = Tween<double>(begin: -1.2, end: 1.8).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _introController.forward().then((_) {
      if (mounted) {
        _ambientController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF071426), // Premium Deep Midnight Background
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient cyan radial glow
          AnimatedBuilder(
            animation: Listenable.merge([_introController, _ambientController]),
            builder: (context, child) {
              final introOpacity = _glowOpacity.value;
              final introScale = _glowScale.value;
              final ambientVal = _introController.isCompleted ? _ambientGlow.value : 1.0;

              if (introOpacity <= 0.01) return const SizedBox.shrink();

              return Opacity(
                opacity: (introOpacity * ambientVal).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: introScale,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF19D9F5).withValues(alpha: 0.28),
                          blurRadius: 100,
                          spreadRadius: 30,
                        ),
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.20),
                          blurRadius: 140,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Center Branding Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Animated Logo Container
                AnimatedBuilder(
                  animation: Listenable.merge([_introController, _ambientController]),
                  builder: (context, child) {
                    final logoOp = _logoOpacity.value;
                    final logoSc = _logoScale.value;
                    final capY = _capSlideY.value;
                    final swingAngle = _tasselSwing.value;
                    final ambientSc = _introController.isCompleted ? _ambientScale.value : 1.0;

                    if (logoOp <= 0.01) return const SizedBox(height: 140);

                    return Opacity(
                      opacity: logoOp.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: logoSc * ambientSc,
                        child: Transform.translate(
                          offset: Offset(0, capY),
                          child: Transform.rotate(
                            angle: swingAngle * math.pi,
                            child: Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    blurRadius: 32,
                                    offset: const Offset(0, 16),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF19D9F5).withValues(alpha: 0.35),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(34),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      'assets/icon/ewumate.png',
                                      fit: BoxFit.cover,
                                    ),
                                    // Ambient light sheen sweep across logo
                                    if (_introController.isCompleted)
                                      ShaderMask(
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            begin: Alignment(_ambientSheen.value - 0.4, -1),
                                            end: Alignment(_ambientSheen.value + 0.4, 1),
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withValues(alpha: 0.3),
                                              Colors.transparent,
                                            ],
                                          ).createShader(bounds);
                                        },
                                        blendMode: BlendMode.srcOver,
                                        child: Container(color: Colors.transparent),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 26),

                // 1.0s: App Name ("EWUMate")
                AnimatedBuilder(
                  animation: _introController,
                  builder: (context, child) {
                    final op = _nameOpacity.value;
                    final slide = _nameSlide.value;

                    return Opacity(
                      opacity: op.clamp(0.0, 1.0),
                      child: SlideTransition(
                        position: AlwaysStoppedAnimation(slide),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.6,
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(text: 'EWU'),
                              TextSpan(
                                text: 'Mate',
                                style: TextStyle(
                                  color: Color(0xFF19D9F5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),

                // 1.2s: Tagline ("YOUR UNIVERSITY COMPANION")
                AnimatedBuilder(
                  animation: _introController,
                  builder: (context, child) {
                    final op = _taglineOpacity.value;
                    final slide = _taglineSlide.value;

                    return Opacity(
                      opacity: op.clamp(0.0, 1.0),
                      child: SlideTransition(
                        position: AlwaysStoppedAnimation(slide),
                        child: const Text(
                          'YOUR UNIVERSITY COMPANION',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.2,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 3),

                // Status Bar & Indicator
                AnimatedBuilder(
                  animation: Listenable.merge([_introController, _ambientController]),
                  builder: (context, child) {
                    final op = _statusOpacity.value;
                    final sheenPos = _ambientSheen.value.clamp(-1.0, 1.0);

                    return Opacity(
                      opacity: op.clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Column(
                          children: [
                            // Glowing Cyan Progress Capsule
                            Container(
                              width: 100,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: FractionallySizedBox(
                                alignment: Alignment(sheenPos, 0),
                                widthFactor: 0.45,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF19D9F5),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF19D9F5).withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.statusText,
                              style: TextStyle(
                                fontFamily: 'Sora',
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (widget.trailing != null) ...[
                              const SizedBox(height: 8),
                              widget.trailing!,
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
