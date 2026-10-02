import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/bindings/app_binding.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/utils/theme_controller.dart';
import 'app/core/values/app_config.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // ThemeController is registered before runApp so the root Obx can observe
  // it from the very first frame (InitialBinding must not re-register it).
  Get.put<ThemeController>(ThemeController(), permanent: true);

  // Edge-to-edge arena look.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const QuizArenaApp());
}

class QuizArenaApp extends StatelessWidget {
  const QuizArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    // Rebuilds the MaterialApp (and the whole tree) on light/dark toggle.
    return Obx(
      () => GetMaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: theme.mode.value,
        initialBinding: InitialBinding(),
        initialRoute: Routes.splash,
        getPages: AppPages.pages,
        defaultTransition: Transition.fadeIn,
      ),
    );
  }
}
