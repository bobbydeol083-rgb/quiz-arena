import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/providers/api_service.dart';
import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/data/repositories/social_repository.dart';
import 'package:quiz_arena/app/modules/duel/controllers/realtime_controller.dart';

/// Nearby players flow: location permission -> post location heartbeat ->
/// fetch nearby players. Sends realtime duel invites over the socket.
///
/// [status] is one of idle | loading | denied | error | ready.
class NearbyController extends GetxController {
  final SocialRepository social;
  final SocketService socket;

  NearbyController({required this.social, required this.socket});

  final RxString status = 'idle'.obs;
  final RxList<NearbyPlayer> players = <NearbyPlayer>[].obs;
  final RxString error = ''.obs;
  final RxString selectedCategory = 'science'.obs;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    status.value = 'loading';
    error.value = '';
    try {
      final serviceOk = await Geolocator.isLocationServiceEnabled();
      if (!serviceOk) {
        status.value = 'denied';
        error.value = 'Location services are off';
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        status.value = 'denied';
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      await social.postLocation(lng: pos.longitude, lat: pos.latitude);
      players.assignAll(await social.nearby());
      status.value = 'ready';
    } on ApiException catch (e) {
      // Offline: stay on the ready screen with an empty list (demo note).
      status.value = e.isNetworkError ? 'ready' : 'error';
      error.value = e.message;
    }
  }

  Future<void> refresh() => init();

  /// Send a realtime duel invite for the selected category.
  void invite(NearbyPlayer p) {
    if (!socket.isConnected) {
      Get.snackbar(
        'Offline',
        'Connect to the backend to send duel invites.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    socket.sendDuelInvite(p.id, selectedCategory.value);
    // The server's game:start carries no opponent — stash them now so the
    // quiz screen can show who we are dueling.
    if (Get.isRegistered<RealtimeController>()) {
      Get.find<RealtimeController>()
          .setPendingOpponent(name: p.username, id: p.id);
    }
    Get.snackbar(
      'Invite sent',
      'Waiting for ${p.username}…',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}
