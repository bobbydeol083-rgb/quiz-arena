import 'package:flutter/foundation.dart';

/// Central app configuration.
///
/// The backend base URL resolves in this order:
/// 1. Runtime override (Settings screen -> persisted in GetStorage).
/// 2. `--dart-define=API_BASE=https://my-server/api`.
/// 3. Platform default: Android emulator -> 10.0.2.2, everything else ->
///    localhost.
class AppConfig {
  AppConfig._();

  static const String appName = 'QuizArena';
  static const String appVersion = '1.0.0';

  /// Backend API version prefix is part of the base URL.
  static const String _androidEmulatorBase = 'http://10.0.2.2:5000/api';
  static const String _defaultBase = 'http://localhost:5000/api';

  static String? _override;

  /// Set at runtime (e.g. from the Settings screen). Persisted by the
  /// caller in GetStorage under `settings_api_base`.
  static set overrideBase(String? value) => _override = value;
  static String? get overrideBase => _override;

  static String get apiBase {
    final o = _override;
    if (o != null && o.trim().isNotEmpty) return o.trim();
    const fromDefine = String.fromEnvironment('API_BASE');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorBase;
    }
    return _defaultBase;
  }

  /// Socket.io connects to the server root (no `/api` suffix).
  static String get socketUrl {
    final base = apiBase;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  // ---- Gameplay tuning -------------------------------------------------
  static const int soloQuestionSeconds = 20;
  static const int blitzTotalSeconds = 60;
  static const int marathonQuestionSeconds = 15;
  static const int marathonLives = 3;
  static const int duelQuestionSeconds = 15;
  static const int soloQuestionCount = 10;
  static const int dailyQuestionCount = 10;

  // ---- Storage keys -----------------------------------------------------
  static const String kToken = 'auth_token';
  static const String kRefreshToken = 'auth_refresh_token';
  static const String kUser = 'auth_user';
  static const String kProgress = 'player_progress';
  static const String kBadges = 'unlocked_badges';
  static const String kThemeMode = 'settings_theme_mode';
  static const String kApiBase = 'settings_api_base';
  static const String kSound = 'settings_sound';
  static const String kHaptics = 'settings_haptics';
  static const String kOnboarded = 'has_onboarded';
}
