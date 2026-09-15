import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class EwuColors extends ThemeExtension<EwuColors> {
  final Color primaryNavy;
  final Color surfaceNavyBlue;
  final Color surfaceElevated;
  final Color primaryCyan;
  final Color secondarySoftBlue;
  final Color borderSubtle;
  final Color borderFocus;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color success;
  final Color warning;
  final Color error;
  final Color academic;
  final Color info;
  final bool isDark;

  Color get textPrimary => primaryText;
  Color get textSecondary => secondaryText;
  Color get textTertiary => tertiaryText;
  Color get accentAlert => error;
  Color get accentAmber => warning;
  Color get surfaceCardNavy => surfaceElevated;

  const EwuColors({
    required this.primaryNavy,
    required this.surfaceNavyBlue,
    required this.surfaceElevated,
    required this.primaryCyan,
    required this.secondarySoftBlue,
    required this.borderSubtle,
    required this.borderFocus,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.success,
    required this.warning,
    required this.error,
    required this.academic,
    required this.info,
    required this.isDark,
  });

  static const dark = EwuColors(
    primaryNavy: AppColors.primaryNavy, // #071426
    surfaceNavyBlue: AppColors.surfaceNavyBlue, // #0D2342
    surfaceElevated: Color(0xFF132F56),
    primaryCyan: AppColors.primaryCyan, // #19D9F5
    secondarySoftBlue: AppColors.secondarySoftBlue, // #5EA8FF
    borderSubtle: Color(0x1FFFFFFF), // white 12%
    borderFocus: AppColors.primaryCyan,
    primaryText: AppColors.primaryText, // white
    secondaryText: AppColors.secondaryText, // #8493A8
    tertiaryText: Color(0xFF64748B),
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    academic: AppColors.academic,
    info: AppColors.info,
    isDark: true,
  );

  static const light = EwuColors(
    primaryNavy: Color(0xFFF8FAFC), // Crisp Slate Background
    surfaceNavyBlue: Colors.white, // Crisp White Cards
    surfaceElevated: Color(0xFFF1F5F9), // Soft Muted Gray Elevation
    primaryCyan: Color(0xFF0284C7), // High-contrast Ocean Cyan/Blue
    secondarySoftBlue: Color(0xFF2563EB), // Royal Blue
    borderSubtle: Color(0x140F172A), // Subtle Slate Border 8%
    borderFocus: Color(0xFF0284C7),
    primaryText: Color(0xFF0F172A), // Dark Slate
    secondaryText: Color(0xFF64748B), // Slate Gray
    tertiaryText: Color(0xFF94A3B8), // Muted Gray
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    academic: Color(0xFF7C3AED),
    info: Color(0xFF0284C7),
    isDark: false,
  );

  @override
  EwuColors copyWith({
    Color? primaryNavy,
    Color? surfaceNavyBlue,
    Color? surfaceElevated,
    Color? primaryCyan,
    Color? secondarySoftBlue,
    Color? borderSubtle,
    Color? borderFocus,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? success,
    Color? warning,
    Color? error,
    Color? academic,
    Color? info,
    bool? isDark,
  }) {
    return EwuColors(
      primaryNavy: primaryNavy ?? this.primaryNavy,
      surfaceNavyBlue: surfaceNavyBlue ?? this.surfaceNavyBlue,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      primaryCyan: primaryCyan ?? this.primaryCyan,
      secondarySoftBlue: secondarySoftBlue ?? this.secondarySoftBlue,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderFocus: borderFocus ?? this.borderFocus,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      academic: academic ?? this.academic,
      info: info ?? this.info,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  EwuColors lerp(ThemeExtension<EwuColors>? other, double t) {
    if (other is! EwuColors) return this;
    return EwuColors(
      primaryNavy: Color.lerp(primaryNavy, other.primaryNavy, t) ?? primaryNavy,
      surfaceNavyBlue: Color.lerp(surfaceNavyBlue, other.surfaceNavyBlue, t) ?? surfaceNavyBlue,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t) ?? surfaceElevated,
      primaryCyan: Color.lerp(primaryCyan, other.primaryCyan, t) ?? primaryCyan,
      secondarySoftBlue: Color.lerp(secondarySoftBlue, other.secondarySoftBlue, t) ?? secondarySoftBlue,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t) ?? borderFocus,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t) ?? tertiaryText,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      academic: Color.lerp(academic, other.academic, t) ?? academic,
      info: Color.lerp(info, other.info, t) ?? info,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension EwuThemeContext on BuildContext {
  EwuColors get ewuColors => Theme.of(this).extension<EwuColors>() ?? EwuColors.dark;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
