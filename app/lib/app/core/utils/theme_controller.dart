import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../theme/app_theme.dart';
import '../values/app_config.dart';

/// Reactive light/dark theme switch, persisted in GetStorage.
class ThemeController extends GetxController {
  final Rx<ThemeMode> mode = ThemeMode.dark.obs;

  @override
  void onInit() {
    super.onInit();
    final stored = GetStorage().read<String>(AppConfig.kThemeMode);
    mode.value = stored == 'light' ? ThemeMode.light : ThemeMode.dark;
    arenaBrightness.value =
        isDark ? Brightness.dark : Brightness.light;
  }

  bool get isDark => mode.value == ThemeMode.dark;

  Future<void> toggle() async {
    mode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    arenaBrightness.value =
        isDark ? Brightness.dark : Brightness.light;
    await GetStorage().write(
      AppConfig.kThemeMode,
      isDark ? 'dark' : 'light',
    );
    Get.changeThemeMode(mode.value);
  }

  Future<void> setDark(bool dark) async {
    if (dark == isDark) return;
    await toggle();
  }
}
