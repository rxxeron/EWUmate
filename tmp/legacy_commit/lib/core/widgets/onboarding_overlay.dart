import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import '../services/tutorial_service.dart';

class OnboardingOverlay extends StatelessWidget {
  final String featureKey;
  final List<OnboardingStep> steps;
  final VoidCallback? onComplete;

  const OnboardingOverlay({
    super.key,
    required this.featureKey,
    required this.steps,
    this.onComplete,
  });

  static void show({
    required BuildContext context,
    required String featureKey,
    required List<OnboardingStep> steps,
    VoidCallback? onComplete,
  }) async {
    final tutorialService = TutorialService();
    if (await tutorialService.hasSeen(featureKey)) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => OnboardingOverlay(
        featureKey: featureKey,
        steps: steps,
        onComplete: onComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingDialogBody(
      featureKey: featureKey,
      steps: steps,
      onComplete: onComplete,
    );
  }
}

class _OnboardingDialogBody extends StatefulWidget {
  final String featureKey;
  final List<OnboardingStep> steps;
  final VoidCallback? onComplete;

  const _OnboardingDialogBody({
    required this.featureKey,
    required this.steps,
    this.onComplete,
  });

  @override
  State<_OnboardingDialogBody> createState() => _OnboardingDialogBodyState();
}

class _OnboardingDialogBodyState extends State<_OnboardingDialogBody> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassContainer(
          height: 440,
          width: double.infinity,
          borderRadius: BorderRadius.circular(32),
          borderWidth: 1.5,
          color: Colors.white.withValues(alpha: 0.05),
          borderColor: Colors.white.withValues(alpha: 0.2),
          blur: 15,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentStep = idx),
                  itemCount: widget.steps.length,
                  itemBuilder: (context, index) {
                    final step = widget.steps[index];
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(step.icon, size: 64, color: Colors.cyanAccent),
                          const SizedBox(height: 24),
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            step.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32, left: 32, right: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step Indicators
                    Row(
                      children: List.generate(
                        widget.steps.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentStep == index
                                ? Colors.cyanAccent
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    // Action Button
                    ElevatedButton(
                      onPressed: () async {
                        if (_currentStep < widget.steps.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          await TutorialService().markAsSeen(widget.featureKey);
                          if (context.mounted) Navigator.pop(context);
                          widget.onComplete?.call();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        _currentStep < widget.steps.length - 1 ? "Next" : "Got it!",
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
