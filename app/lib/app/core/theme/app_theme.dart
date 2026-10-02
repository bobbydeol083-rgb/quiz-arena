import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global brightness mirror, updated by [ThemeController].
///
/// [AppColors.adaptivePrimary]/[adaptiveSecondary]/[adaptiveMuted] read this
/// at build time. Toggling the theme rebuilds the whole widget tree (via
/// GetMaterialApp), so every build re-evaluates with the correct brightness —
/// no BuildContext threading needed in view helpers.
final ValueNotifier<Brightness> arenaBrightness =
    ValueNotifier(Brightness.dark);

/// QuizArena "midnight arena" palette.
///
/// Dark-first: deep space blues, electric violet -> cyan gradients,
/// glassmorphism surfaces. Light mode is a soft lavender variant.
class AppColors {
  AppColors._();

  // ---- Dark (primary) ---------------------------------------------------
  static const Color midnight = Color(0xFF070714);
  static const Color midnightSoft = Color(0xFF0D0D24);
  static const Color surface = Color(0xFF12122B);
  static const Color surfaceElevated = Color(0xFF1A1A38);
  static const Color glass = Color(0x14FFFFFF); // white 8%
  static const Color glassBorder = Color(0x26FFFFFF); // white 15%

  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetDeep = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color magenta = Color(0xFFE879F9);

  static const Color textPrimary = Color(0xFFF4F4FB);
  static const Color textSecondary = Color(0xFFA5A5C7);
  static const Color textMuted = Color(0xFF6E6E96);

  static const Color success = Color(0xFF34D399);
  static const Color successDim = Color(0xFF065F46);
  static const Color error = Color(0xFFF87171);
  static const Color errorDim = Color(0xFF7F1D1D);
  static const Color warning = Color(0xFFFBBF24);
  static const Color gold = Color(0xFFFCD34D);

  // ---- Light -------------------------------------------------------------
  static const Color lightBg = Color(0xFFF4F3FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF17172E);
  static const Color lightTextSecondary = Color(0xFF5B5B7E);

  // ---- Level tiers --------------------------------------------------------
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFC0C7D1);
  static const Color goldTier = Color(0xFFF5C044);
  static const Color platinum = Color(0xFF7DE8F0);
  static const Color diamond = Color(0xFF9D8CFF);

  static Color tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'silver':
        return silver;
      case 'gold':
        return goldTier;
      case 'platinum':
        return platinum;
      case 'diamond':
        return diamond;
      case 'bronze':
      default:
        return bronze;
    }
  }

  /// Category accent colors, keyed by category id.
  static Color categoryColor(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'science':
        return cyan;
      case 'sports':
        return success;
      case 'history':
        return warning;
      case 'technology':
        return violet;
      case 'geography':
        return Color(0xFF60A5FA);
      case 'entertainment':
        return magenta;
      default:
        return violet;
    }
  }

  /// Category emoji glyphs (no image assets needed).
  static String categoryEmoji(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'science':
        return '🔬';
      case 'sports':
        return '⚽';
      case 'history':
        return '🏛️';
      case 'technology':
        return '💻';
      case 'geography':
        return '🌍';
      case 'entertainment':
        return '🎬';
      default:
        return '🧠';
    }
  }

  // ---- Brightness-adaptive text colors --------------------------------------
  // Views must use these (not the raw consts) for text painted on adaptive
  // surfaces, so the light-mode toggle keeps everything readable.
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimaryOf(BuildContext context) =>
      _isDark(context) ? textPrimary : lightText;

  static Color textSecondaryOf(BuildContext context) =>
      _isDark(context) ? textSecondary : lightTextSecondary;

  static Color textMutedOf(BuildContext context) =>
      _isDark(context) ? textMuted : const Color(0xFF8E8EA8);

  // ---- Context-free adaptive aliases -----------------------------------------
  // Same as the *Of(context) variants above, but driven by [arenaBrightness]
  // so view helper methods (which often lack a BuildContext) stay readable.
  // Safe because a theme toggle rebuilds the entire tree.
  static Color get adaptivePrimary =>
      arenaBrightness.value == Brightness.dark ? textPrimary : lightText;

  static Color get adaptiveSecondary => arenaBrightness.value == Brightness.dark
      ? textSecondary
      : lightTextSecondary;

  static Color get adaptiveMuted => arenaBrightness.value == Brightness.dark
      ? textMuted
      : const Color(0xFF8E8EA8);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.violet, AppColors.cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryVertical = LinearGradient(
    colors: [AppColors.violetDeep, AppColors.violet, AppColors.cyan],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardSheen = LinearGradient(
    colors: [Color(0x1FFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackground = LinearGradient(
    colors: [AppColors.midnight, AppColors.midnightSoft],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient glowViolet = RadialGradient(
    colors: [Color(0x557C3AED), Color(0x007C3AED)],
    radius: 0.9,
  );

  static const RadialGradient glowCyan = RadialGradient(
    colors: [Color(0x4422D3EE), Color(0x0022D3EE)],
    radius: 0.9,
  );
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color display, Color body) {
    final base = GoogleFonts.interTextTheme();
    final displayFont = GoogleFonts.soraTextTheme();
    return base.copyWith(
      displayLarge: displayFont.displayLarge
          ?.copyWith(color: display, fontWeight: FontWeight.w800, fontSize: 34),
      displayMedium: displayFont.displayMedium
          ?.copyWith(color: display, fontWeight: FontWeight.w800, fontSize: 28),
      displaySmall: displayFont.displaySmall
          ?.copyWith(color: display, fontWeight: FontWeight.w700, fontSize: 24),
      headlineMedium: displayFont.headlineMedium
          ?.copyWith(color: display, fontWeight: FontWeight.w700, fontSize: 20),
      headlineSmall: displayFont.headlineSmall
          ?.copyWith(color: display, fontWeight: FontWeight.w700, fontSize: 18),
      titleLarge:
          base.titleLarge?.copyWith(color: display, fontWeight: FontWeight.w700),
      titleMedium:
          base.titleMedium?.copyWith(color: display, fontWeight: FontWeight.w600),
      titleSmall:
          base.titleSmall?.copyWith(color: display, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(color: body),
      bodyMedium: base.bodyMedium?.copyWith(color: body),
      bodySmall: base.bodySmall?.copyWith(color: body),
      labelLarge:
          base.labelLarge?.copyWith(color: display, fontWeight: FontWeight.w700),
      labelMedium: base.labelMedium?.copyWith(color: body),
      labelSmall: base.labelSmall?.copyWith(color: body),
    );
  }

  static ThemeData dark() {
    final scheme = const ColorScheme.dark(
      primary: AppColors.violet,
      secondary: AppColors.cyan,
      tertiary: AppColors.magenta,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.midnight,
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.violet, width: 1.6),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static ThemeData light() {
    final scheme = const ColorScheme.light(
      primary: AppColors.violetDeep,
      secondary: AppColors.cyan,
      tertiary: AppColors.magenta,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.lightText,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: _textTheme(AppColors.lightText, AppColors.lightTextSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.lightText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: AppColors.violetDeep.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.violetDeep, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
