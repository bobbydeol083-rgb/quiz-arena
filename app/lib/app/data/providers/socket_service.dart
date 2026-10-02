import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/values/app_config.dart';

/// Socket.io event names — the exact realtime contract shared with the
/// backend (namespace `/`).
class SocketEvents {
  SocketEvents._();

  // client -> server
  static const String authenticate = 'authenticate';
  static const String matchmakingJoin = 'matchmaking:join';
  static const String matchmakingLeave = 'matchmaking:leave';
  static const String duelInvite = 'duel:invite';
  static const String duelAccept = 'duel:accept';
  static const String duelDecline = 'duel:decline';
  static const String roomCreate = 'room:create';
  static const String roomJoin = 'room:join';
  static const String roomLeave = 'room:leave';
  static const String gameAnswer = 'game:answer';

  // server -> client
  static const String matchFound = 'match:found';
  static const String duelInvited = 'duel:invited';
  static const String duelAccepted = 'duel:accepted';
  static const String gameStart = 'game:start';
  static const String gameScore = 'game:score';
  static const String gameEnd = 'game:end';
  // server -> client (party rooms — names verified against the backend)
  static const String roomCreated = 'room:created';
  static const String roomUpdate = 'room:update';

  // ---- Bluff & Brain (client -> server) ----
  static const String bluffFake = 'bluff:fake';
  static const String bluffVote = 'bluff:vote';
  static const String bluffPowerup = 'bluff:powerup';

  // ---- Bluff & Brain (server -> client) ----
  static const String bluffStart = 'bluff:start';
  static const String bluffRound = 'bluff:round';
  static const String bluffFakesIn = 'bluff:fakes_in';
  static const String bluffVotePhase = 'bluff:vote';
  static const String bluffReveal = 'bluff:reveal';
  static const String bluffEnd = 'bluff:end';
  static const String bluffPowerupResult = 'bluff:powerup_result';
  static const String bluffPlayerLeft = 'bluff:player_left';
}

/// Wraps socket_io_client with the app's auth token. All realtime features
/// (matchmaking, duel invites, party rooms, live scores) go through here.
///
/// The service degrades gracefully: every emit is a no-op while
/// disconnected, so UI code never has to null-check the socket.
class SocketService extends GetxService {
  io.Socket? _socket;

  final RxBool connected = false.obs;
  final RxString lastError = ''.obs;

  bool get isConnected => connected.value && _socket != null;

  /// Connect to the socket server with the user's auth token.
  Future<void> connect(String token) async {
    disconnect();
    lastError.value = '';
    try {
      _socket = io.io(
        AppConfig.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );
      _socket!
        ..onConnect((_) {
          connected.value = true;
          // Belt & braces: also send the token over the wire in case the
          // server expects the explicit authenticate event.
          emit(SocketEvents.authenticate, {'token': token});
        })
        ..onDisconnect((_) => connected.value = false)
        ..onConnectError((err) {
          lastError.value = 'Connection failed: $err';
        })
        ..onError((err) {
          lastError.value = 'Socket error: $err';
        });
      _socket!.connect();
    } catch (e) {
      lastError.value = 'Could not open socket: $e';
    }
  }

  void disconnect() {
    try {
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    connected.value = false;
  }

  /// Raw emit — no-op when disconnected.
  void emit(String event, [dynamic data]) {
    if (!isConnected) return;
    try {
      if (data == null) {
        _socket!.emit(event);
      } else {
        _socket!.emit(event, data);
      }
    } catch (_) {}
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  // ---- Typed helpers (client -> server contract) ---------------------------
  void joinMatchmaking(String category) =>
      emit(SocketEvents.matchmakingJoin, {'category': category});

  void leaveMatchmaking() => emit(SocketEvents.matchmakingLeave);

  void sendDuelInvite(String toUserId, String category) =>
      emit(SocketEvents.duelInvite, {'toUserId': toUserId, 'category': category});

  void acceptDuel(String inviteId) =>
      emit(SocketEvents.duelAccept, {'inviteId': inviteId});

  void declineDuel(String inviteId) =>
      emit(SocketEvents.duelDecline, {'inviteId': inviteId});

  void createRoom(String mode, String category) =>
      emit(SocketEvents.roomCreate, {'mode': mode, 'category': category});

  void joinRoom(String code) => emit(SocketEvents.roomJoin, {'code': code});

  void leaveRoom() => emit(SocketEvents.roomLeave);

  void sendAnswer(String questionId, int selectedIndex) =>
      emit(SocketEvents.gameAnswer, {
        'questionId': questionId,
        'selectedIndex': selectedIndex,
      });

  // ---- Bluff & Brain typed helpers ----------------------------------------
  void createBluffRoom(String category) =>
      emit(SocketEvents.roomCreate, {'mode': 'bluff', 'category': category});

  void submitBluffFake(String text) =>
      emit(SocketEvents.bluffFake, {'text': text});

  void voteBluff(String optionId) =>
      emit(SocketEvents.bluffVote, {'optionId': optionId});

  void useBluffPowerup(String type, {String? targetUserId}) => emit(
        SocketEvents.bluffPowerup,
        {
          'type': type,
          if (targetUserId != null) 'targetUserId': targetUserId,
        },
      );

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
