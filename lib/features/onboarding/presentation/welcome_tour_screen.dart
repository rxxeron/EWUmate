import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/onboarding_steps.dart';
import '../../../core/services/tutorial_service.dart';
import '../../../core/widgets/onboarding_overlay.dart';

/// Full-screen premium Welcome Tour shown once after first login.
/// Introduces every major feature of EWUmate before the user lands on the dashboard.
class WelcomeTourScreen extends StatefulWidget {
  const WelcomeTourScreen({super.key});

  @override
  State<WelcomeTourScreen> createState() => _WelcomeTourScreenState();
}

class _WelcomeTourScreenState extends State<WelcomeTourScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  late final AnimationController _pulseController;

  List<OnboardingStep> get _steps => OnboardingSteps.welcomeTour;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _completeTour() async {
    await TutorialService().markAsSeen(OnboardingSteps.welcomeTourKey);
    if (mounted) {
      context.go('/dashboard');
    }
  }

  void _nextPage() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeTour();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040A14),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF091A33),
              Color(0xFF061224),
              Color(0xFF040A14),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _completeTour,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        'Skip Tour',
                        style: GoogleFonts.sora(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) =>
                      setState(() => _currentStep = idx),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return _WelcomeTourSlide(
                      step: step,
                      index: index,
                      total: _steps.length,
                      pulseAnimation: _pulseController,
                    );
                  },
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentStep == index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentStep == index
                                ? Colors.cyanAccent
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentStep < _steps.length - 1
                              ? 'Next'
                              : "Let's Get Started! 🚀",
                          style: GoogleFonts.sora(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Step counter
                    Text(
                      '${_currentStep + 1} of ${_steps.length}',
                      style: GoogleFonts.sora(
                        color: Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeTourSlide extends StatelessWidget {
  final OnboardingStep step;
  final int index;
  final int total;
  final AnimationController pulseAnimation;

  const _WelcomeTourSlide({
    required this.step,
    required this.index,
    required this.total,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              final scale = 1.0 + (pulseAnimation.value * 0.05);
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.cyanAccent.withValues(alpha: 0.2),
                    Colors.cyanAccent.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    step.icon,
                    size: 36,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              color: Colors.white60,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
