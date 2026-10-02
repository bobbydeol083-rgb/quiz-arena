import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/values/app_config.dart';
import '../models/models.dart';
import '../providers/api_service.dart';
import '../providers/socket_service.dart';

/// Owns the session: tokens, current user, login/register/logout, silent
/// refresh, and socket lifecycle.
///
/// Offline behavior: when the backend is unreachable, [loginOfflineDemo]
/// creates a local demo profile so the app stays fully usable.
class AuthRepository extends GetxService {
  final ApiService api;
  final GetStorage box;

  final Rx<AppUser?> currentUser = Rx<AppUser?>(null);
  final RxBool isLoggingOut = false.obs;

  AuthRepository({required this.api, GetStorage? box})
      : box = box ?? GetStorage();

  @override
  void onInit() {
    super.onInit();
    api.onRefreshToken = _refreshToken;
    loadFromStorage();
  }

  String? get token => box.read<String>(AppConfig.kToken);
  String? get refreshToken => box.read<String>(AppConfig.kRefreshToken);
  bool get isLoggedIn => token != null && currentUser.value != null;
  bool get isOfflineDemo => currentUser.value?.id == 'local-demo';

  Future<void> loadFromStorage() async {
    final storedToken = token;
    if (storedToken == null || storedToken.isEmpty) return;
    api.authToken = storedToken;
    final userJson = box.read<Map>(AppConfig.kUser);
    if (userJson != null) {
      currentUser.value =
          AppUser.fromJson(Map<String, dynamic>.from(userJson));
    }
    // Open the realtime channel for invites / matchmaking.
    if (Get.isRegistered<SocketService>()) {
      await Get.find<SocketService>().connect(storedToken);
    }
    // Best-effort profile refresh; keep cached profile when offline.
    try {
      final json = await api.me();
      final user = AppUser.fromJson(
          Map<String, dynamic>.from(json['user'] as Map? ?? json));
      currentUser.value = user;
      await box.write(AppConfig.kUser, user.toJson());
    } on ApiException {
      // Offline — cached profile stands.
    }
  }

  Future<AppUser> _persistSession(Map<String, dynamic> json) async {
    final token = json['token'] as String?;
    final refresh = json['refreshToken'] as String?;
    final userJson = json['user'] as Map?;
    if (token == null || userJson == null) {
      throw const ApiException('Malformed auth response from server.');
    }
    final user =
        AppUser.fromJson(Map<String, dynamic>.from(userJson));
    await box.write(AppConfig.kToken, token);
    if (refresh != null) await box.write(AppConfig.kRefreshToken, refresh);
    await box.write(AppConfig.kUser, user.toJson());
    api.authToken = token;
    currentUser.value = user;
    if (Get.isRegistered<SocketService>()) {
      await Get.find<SocketService>().connect(token);
    }
    return user;
  }

  Future<AppUser> login(String email, String password) async {
    final json = await api.login(email.trim(), password);
    return _persistSession(json);
  }

  Future<AppUser> register(
      String username, String email, String password) async {
    final json =
        await api.register(username.trim(), email.trim(), password);
    return _persistSession(json);
  }

  /// Continue without a backend: local profile + bundled questions.
  Future<AppUser> loginOfflineDemo() async {
    final user = AppUser.demo();
    final stored = box.read<Map>(AppConfig.kUser);
    AppUser effective = user;
    if (stored != null) {
      final prev = AppUser.fromJson(Map<String, dynamic>.from(stored));
      if (prev.id == 'local-demo') effective = prev;
    }
    await box.write(AppConfig.kUser, effective.toJson());
    await box.remove(AppConfig.kToken);
    await box.remove(AppConfig.kRefreshToken);
    api.authToken = null;
    currentUser.value = effective;
    return effective;
  }

  Future<String?> _refreshToken() async {
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return null;
    try {
      final json = await api.refresh(rt);
      final fresh = json['token'] as String?;
      if (fresh == null || fresh.isEmpty) return null;
      await box.write(AppConfig.kToken, fresh);
      return fresh;
    } on ApiException {
      return null;
    }
  }

  /// Apply a finished game's rewards to the local profile (used for both
  /// online and offline grading paths).
  Future<void> applyResult(QuizSubmitResult result) async {
    final user = currentUser.value;
    if (user == null) return;
    final updated = user.copyWith(
      xp: user.xp + result.xpEarned,
      coins: user.coins + result.coinsEarned,
      streak: result.streak,
    );
    currentUser.value = updated;
    await box.write(AppConfig.kUser, updated.toJson());
  }

  Future<void> logout() async {
    isLoggingOut.value = true;
    try {
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().disconnect();
      }
      await box.remove(AppConfig.kToken);
      await box.remove(AppConfig.kRefreshToken);
      await box.remove(AppConfig.kUser);
      api.authToken = null;
      currentUser.value = null;
    } finally {
      isLoggingOut.value = false;
    }
  }
}
