import 'package:flutter/widgets.dart';

/// Spacing, radii, durations — single source of truth so the UI stays
/// consistent across modules.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 350);
  static const Duration stagger = Duration(milliseconds: 70);
}

class AppCurves {
  AppCurves._();
  static const Curve entrance = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve snappy = Curves.easeOutBack;
}

class AppInsets {
  AppInsets._();
  static const EdgeInsets screen =
      EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md);
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.lg);
}
