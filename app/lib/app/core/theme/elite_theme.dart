import 'package:flutter/material.dart';

/// Elite Quiz design tokens — the visual language of the Elite Quiz app
/// (WRTeam v2.3.7), applied to the harvested feature screens.
/// Primary brand color is Elite pink; page background is cool grey-blue.
class EliteTheme {
  /// Set true in widget tests — GoogleFonts cannot fetch fonts without
  /// network access, so [eliteText] falls back to the system font there.
  static bool useSystemFont = false;

  // ---- Brand ---------------------------------------------------------------
  static const Color primary = Color(0xFFEF5388); // Elite pink (light theme)
  static const Color primaryDark = Color(0xFFF279A2); // Elite pink (dark theme)
  static const Color primaryText = Color(0xFF45536D); // slate body text
  static const Color pageBg = Color(0xFFF3F7FA); // cool grey-blue page bg
  static const Color surface = Color(0xFFFFFFFF);

  // ---- Shared semantic colors (same as Elite) ------------------------------
  static const Color correct = Color(0xFF5DB760);
  static const Color wrong = Color(0xFFFF6169);
  static const Color hurry = Color(0xFFFF6169);
  static const Color pending = Colors.orangeAccent;
  static const Color addCoin = Color(0xFF5DB760);
  static const Color stepGreen = Color(0xFF22C274);

  // ---- Derived --------------------------------------------------------------
  static Color primaryDim(double alpha) =>
      primary.withValues(alpha: alpha);

  static const double cardRadius = 15;
  static const double buttonRadius = 8;
  static const double headerRadius = 10;

  /// Elite's rounded CTA button.
  static Widget roundedButton({
    required String title,
    required VoidCallback onTap,
    double widthFactor = 0.9,
    double height = 58,
    Color backgroundColor = primary,
    Color titleColor = Colors.white,
    double textSize = 18,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: textSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  /// Elite-style screen header: pink band with curved bottom edge.
  static Widget headerBand({
    required BuildContext context,
    required String title,
    Widget? illustration,
    List<Widget> extra = const [],
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: primary,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(headerRadius)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (illustration != null) ...[
            const SizedBox(height: 12),
            illustration,
          ],
          ...extra,
        ],
      ),
    );
  }

  /// Elite-style back button (pink on light surfaces).
  static Widget backButton(BuildContext context, {Color color = primary}) {
    return IconButton(
      color: color,
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
