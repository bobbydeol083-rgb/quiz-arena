import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:quiz_arena/app/core/utils/theme_controller.dart';
import 'package:quiz_arena/app/core/values/app_config.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// App settings: theme, backend base URL, sound/haptics preferences,
/// progress reset and logout.
class SettingsController extends GetxController {
  final AuthRepository auth;
  final ApiService api;
  final ThemeController theme;
  final ProgressRepository progressRepo;

  SettingsController({
    required this.auth,
    required this.api,
    required this.theme,
    required this.progressRepo,
  });

  late final TextEditingController apiCtrl;
  final RxBool saving = false.obs;
  final RxBool sound = true.obs;
  final RxBool haptics = true.obs;

  String get version => AppConfig.appVersion;
  AppUser? get user => auth.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    apiCtrl = TextEditingController(text: AppConfig.apiBase);
    final box = GetStorage();
    sound.value = box.read<bool>(AppConfig.kSound) ?? true;
    haptics.value = box.read<bool>(AppConfig.kHaptics) ?? true;
  }

  void toggleTheme() => theme.toggle();

  Future<void> setSound(bool v) async {
    sound.value = v;
    await GetStorage().write(AppConfig.kSound, v);
  }

  Future<void> setHaptics(bool v) async {
    haptics.value = v;
    await GetStorage().write(AppConfig.kHaptics, v);
  }

  /// Persist the backend base URL override (empty restores the default).
  Future<void> saveApiBase() async {
    final v = apiCtrl.text.trim();
    AppConfig.overrideBase = v.isEmpty ? null : v;
    await GetStorage().write(AppConfig.kApiBase, v);
    Get.snackbar('Saved', 'API base updated.');
  }

  /// Ping the backend to verify the configured base URL is reachable.
  Future<void> testConnection() async {
    saving.value = true;
    try {
      await api.categories();
      Get.snackbar('Online', 'Backend is reachable.');
    } on ApiException catch (e) {
      Get.snackbar('Unreachable', e.message);
    } finally {
      saving.value = false;
    }
  }

  Future<void> resetProgress() async {
    Get.defaultDialog(
      title: 'Reset progress?',
      middleText:
          'This clears all stats, streaks and badges stored on this device.',
      textConfirm: 'Reset',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        await progressRepo.reset();
        Get.snackbar('Done', 'Progress has been reset.');
      },
    );
  }

  Future<void> logout() async {
    Get.defaultDialog(
      title: 'Log out?',
      middleText: 'You will need to sign in again to play online.',
      textConfirm: 'Log out',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        await auth.logout();
        Get.offAllNamed(Routes.auth);
      },
    );
  }

  @override
  void onClose() {
    apiCtrl.dispose();
    super.onClose();
  }
}
