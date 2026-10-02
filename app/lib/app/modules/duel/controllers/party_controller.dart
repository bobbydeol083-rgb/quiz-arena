import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/providers/socket_service.dart';

/// Party room: create or join a room by code, watch the player list,
/// and let the host start the game.
class PartyController extends GetxController {
  final SocketService socket;

  PartyController({required this.socket});

  final RxString selectedCategory = 'science'.obs;
  final RxBool creating = false.obs;
  final Rxn<RoomInfo> room = Rxn<RoomInfo>();
  final RxList<RoomPlayer> players = <RoomPlayer>[].obs;
  final RxBool isHost = false.obs;
  final RxString joinCode = ''.obs;
  final TextEditingController joinCodeCtrl = TextEditingController();

  void createRoom() {
    creating.value = true;
    _listenRoomCreatedOnce();
    socket.createRoom('party', selectedCategory.value);
    _guardStuckSpinner();
  }

  void joinRoom() {
    final code = joinCodeCtrl.text.trim();
    if (code.isEmpty) return;
    creating.value = true;
    // The server answers room:join with a room:update broadcast to the room.
    // _onRoomUpdate (registered in onInit) applies it and clears `creating`.
    isHost.value = false;
    socket.joinRoom(code);
    _guardStuckSpinner();
  }

  @override
  void onInit() {
    super.onInit();
    // Persistent listener: refreshes the player list every time anyone joins.
    socket.on(SocketEvents.roomUpdate, _onRoomUpdate);
  }

  /// The server emits `room:created { code }` to the creator only.
  void _listenRoomCreatedOnce() {
    void handler(dynamic data) {
      socket.off(SocketEvents.roomCreated);
      try {
        final map = Map<String, dynamic>.from(data as Map);
        final code = '${map['code'] ?? ''}';
        if (code.isEmpty) return;
        room.value = RoomInfo(
          code: code,
          mode: 'party',
          category: selectedCategory.value,
        );
        isHost.value = true;
      } finally {
        creating.value = false;
      }
    }

    socket.off(SocketEvents.roomCreated);
    socket.on(SocketEvents.roomCreated, handler);
  }

  /// The server emits `room:update { roomId, players: [{id,username,avatar}] }`
  /// to the whole room whenever someone joins.
  void _onRoomUpdate(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final code = '${map['roomId'] ?? map['code'] ?? ''}';
      if (code.isEmpty) return;
      if (room.value == null) {
        // Our own join (or a late update): adopt the room, we are not host.
        room.value = RoomInfo(
          code: code,
          mode: 'party',
          category: selectedCategory.value,
        );
        isHost.value = false;
      }
      final list = (map['players'] as List?) ?? const [];
      players.assignAll(
        list.map(
          (e) => RoomPlayer.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );
      creating.value = false;
    } catch (_) {
      // Keep previous state; the stuck-spinner guard clears `creating`.
    }
  }

  /// Safety net: never leave the "creating" spinner stuck if the server
  /// never answers.
  void _guardStuckSpinner() {
    Future.delayed(const Duration(seconds: 20), () {
      if (room.value == null) creating.value = false;
    });
  }

  void startGame() {
    // Host only: the backend deals the questions on this event and emits
    // game:start to the room (handled globally by RealtimeController).
    socket.emit('room:start');
  }

  void copyCode() {
    final code = room.value?.code;
    if (code == null || code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'Code copied',
      'Share it with your friends to join.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void leave() {
    socket.leaveRoom();
    Get.back();
  }

  @override
  void onClose() {
    socket.off(SocketEvents.roomCreated);
    socket.off(SocketEvents.roomUpdate);
    if (room.value != null) socket.leaveRoom();
    joinCodeCtrl.dispose();
    super.onClose();
  }
}
