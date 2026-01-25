import 'package:flutter/material.dart';

class AppTheme {
  // Cash Flex Brand Colors - Modern Teal & Emerald Green Palette
  static const Color primaryTeal = Color(0xFF14B8A6); // Vibrant teal
  static const Color primaryTealDark = Color(0xFF0D9488);
  static const Color accentEmerald = Color(0xFF10B981); // Emerald green
  static const Color accentEmeraldDark = Color(0xFF059669);
  static const Color secondaryCyan = Color(0xFF06B6D4); // Cyan
  static const Color backgroundLight = Color(0xFFF8FAFC); // Very light gray
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  // Spacing Constants - Normalized spacing scale
  static const double spacingXS = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMediumSmall = 12.0;
  static const double spacingMedium = 16.0; // Most common spacing
  static const double spacingMediumLarge = 20.0;
  static const double spacingLarge = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 40.0;
  
  // Standard padding/margin helpers
  static EdgeInsets get paddingXS => const EdgeInsets.all(spacingXS);
  static EdgeInsets get paddingSmall => const EdgeInsets.all(spacingSmall);
  static EdgeInsets get paddingMedium => const EdgeInsets.all(spacingMedium);
  static EdgeInsets get paddingLarge => const EdgeInsets.all(spacingLarge);
  
  static EdgeInsets get paddingHorizontalMedium => const EdgeInsets.symmetric(horizontal: spacingMedium);
  static EdgeInsets get paddingHorizontalLarge => const EdgeInsets.symmetric(horizontal: spacingLarge);
  static EdgeInsets get paddingVerticalMedium => const EdgeInsets.symmetric(vertical: spacingMedium);
  static EdgeInsets get paddingVerticalLarge => const EdgeInsets.symmetric(vertical: spacingLarge);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF14B8A6), // Teal
        secondary: Color(0xFF10B981), // Emerald
        tertiary: Color(0xFF06B6D4), // Cyan
        surface: Color(0xFF1E293B),
        surfaceContainerHighest: Color(0xFF334155),
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E293B),
        modalBackgroundColor: Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 16,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleSmall: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 14,
          letterSpacing: -0.2,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          letterSpacing: -0.1,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        labelMedium: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        labelSmall: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryTeal,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF14B8A6), // Teal
        secondary: Color(0xFF10B981), // Emerald
        tertiary: Color(0xFF06B6D4), // Cyan
        surface: Colors.white,
        surfaceContainerHighest: Color(0xFFF1F5F9),
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0F172A),
        onBackground: Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 16,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF475569),
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          letterSpacing: -0.2,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          letterSpacing: -0.1,
        ),
        labelLarge: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        labelMedium: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        labelSmall: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  // Cash Flex Brand Gradients - Fresh & Modern
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient1 = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient2 = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border Radius Constants
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusXLarge = 24.0;
  static const double borderRadiusRound = 30.0;

  // Shadow Constants
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryTeal.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadowMedium => [
        BoxShadow(
          color: primaryTeal.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardShadowSmall => [
        BoxShadow(
          color: primaryTeal.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  // Common Colors
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color warningOrange200 = Color(0xFFFFE0B2);
  static const Color warningOrange400 = Color(0xFFFFB74D);
  static const Color warningOrange600 = Color(0xFFFB8C00);
  static const Color warningOrange700 = Color(0xFFF57C00);
  static const Color warningOrange800 = Color(0xFFEF6C00);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color infoBlue = Color(0xFF06B6D4);
  
  // Leaderboard Podium Gradients
  static const LinearGradient leaderboardPodium1Gradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFDAA520)], // Gold
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient leaderboardPodium2Gradient = LinearGradient(
    colors: [Color(0xFFC0C0C0), Color(0xFFA9A9A9)], // Silver
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient leaderboardPodium3Gradient = LinearGradient(
    colors: [Color(0xFFCD7F32), Color(0xFF8B4513)], // Bronze
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Standardized Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        elevation: 0,
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 56),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryTeal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          side: BorderSide(color: primaryTeal, width: 1.5),
        ),
        elevation: 0,
      );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      );

  // Helper method to get gradient button style
  static Widget buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    LinearGradient? gradient,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    final isDisabled = onPressed == null;
    final buttonGradient = gradient ?? primaryGradient;
    
    return Container(
      height: height ?? 56,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [
                  primaryTeal.withOpacity(0.3),
                  accentEmerald.withOpacity(0.3),
                ],
              )
            : buttonGradient,
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: TextStyle(
                color: isDisabled
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
