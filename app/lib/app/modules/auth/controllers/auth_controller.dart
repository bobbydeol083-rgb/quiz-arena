import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Login / register state. Successful auth (or offline demo) clears the
/// stack and drops the user into home.
class AuthController extends GetxController {
  final AuthRepository auth;

  AuthController({required this.auth});

  /// 0 = login, 1 = register.
  final RxInt tab = 0.obs;

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController username = TextEditingController();
  final TextEditingController referralCode = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  void toggleTab(int index) {
    tab.value = index;
    error.value = '';
  }

  Future<void> login() async {
    final address = email.text.trim();
    final pass = password.text;
    if (address.isEmpty || pass.isEmpty) {
      error.value = 'Enter your email and password.';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      await auth.login(address, pass);
      Get.offAllNamed(Routes.home);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    final name = username.text.trim();
    final address = email.text.trim();
    final pass = password.text;
    if (name.length < 3) {
      error.value = 'Username must be at least 3 characters.';
      return;
    }
    if (address.isEmpty || pass.isEmpty) {
      error.value = 'Enter your email and password.';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      await auth.register(name, address, pass,
          referralCode: referralCode.text.trim().isEmpty
              ? null
              : referralCode.text.trim());
      Get.offAllNamed(Routes.home);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueOffline() async {
    isLoading.value = true;
    try {
      await auth.loginOfflineDemo();
      Get.offAllNamed(Routes.home);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    username.dispose();
    referralCode.dispose();
    super.onClose();
  }
}
