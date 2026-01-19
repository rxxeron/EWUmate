import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Time-based sky animation widget using Lottie animations
class SkyAnimationWidget extends StatelessWidget {
  const SkyAnimationWidget({super.key});

  String _getLottieAsset() {
    final hour = DateTime.now().hour;

    // Morning: 5 AM - 11 AM (Sunrise)
    if (hour >= 5 && hour < 11) {
      return 'assets/lottie/Sunrise - Breathe in Breathe out.json';
    }
    // Noon/Afternoon: 11 AM - 5 PM (Sunny)
    if (hour >= 11 && hour < 17) {
      return 'assets/lottie/sunny.json';
    }
    // Evening: 5 PM - 8 PM (Sunset)
    if (hour >= 17 && hour < 20) {
      return 'assets/lottie/Building blocks by sunset.json';
    }
    // Night: 8 PM - 5 AM (Moon)
    return 'assets/lottie/Sleepy Moon.json';
  }

  Color _getBackgroundColor() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return const Color(0xFFFFA726); // Orange for sunrise
    }
    if (hour >= 11 && hour < 17) {
      return const Color(0xFFFFEB3B); // Yellow for sunny
    }
    if (hour >= 17 && hour < 20) {
      return const Color(0xFFFF7043); // Deep orange for sunset
    }
    return const Color(0xFF3F51B5); // Indigo for night
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _getBackgroundColor().withValues(alpha: 0.3),
            _getBackgroundColor().withValues(alpha: 0.1),
          ],
        ),
      ),
      child: ClipOval(
        child: Lottie.asset(
          _getLottieAsset(),
          fit: BoxFit.cover,
          repeat: true,
          animate: true,
        ),
      ),
    );
  }
}

/// Greeting helper function
String getTimeGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return "Good Morning";
  if (hour >= 12 && hour < 17) return "Good Afternoon";
  if (hour >= 17 && hour < 21) return "Good Evening";
  return "Good Night";
}
