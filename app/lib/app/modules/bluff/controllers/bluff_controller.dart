import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/socket_service.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';
import 'bluff_roasts.dart';

/// Phases of a Bluff & Brain round, driven by server events.
enum BluffPhase { lobby, write, vote, reveal, done }

class BluffOption {
  final String id;
  final String text;
  final String? authorId; // only known at reveal

  const BluffOption({required this.id, required this.text, this.authorId});

  bool get isTruth => id == 'truth';
}

class BluffDelta {
  final String userId;
  final int delta;
  final bool votedTruth;
  final int fooled;

  const BluffDelta({
    required this.userId,
    required this.delta,
    required this.votedTruth,
    required this.fooled,
  });
}

class BluffScore {
  final String userId;
  final int score;
  final int truths;
  final int fooled;

  const BluffScore({
    required this.userId,
    required this.score,
    required this.truths,
    required this.fooled,
  });
}

/// Power-up catalogue (ids match the backend).
class BluffPowerups {
  BluffPowerups._();
  static const Map<String, Map<String, String>> all = {
    'detective': {'emoji': '🕵️', 'name': 'Detective', 'desc': 'Eliminate one fake answer'},
    'double_agent': {'emoji': '🎭', 'name': 'Double Agent', 'desc': 'Your bluff pays double'},
    'speed_run': {'emoji': '⏱️', 'name': 'Speed Run', 'desc': 'Fake in 5s → 2x points'},
    'swap': {'emoji': '🔄', 'name': 'Swap', 'desc': "Steal someone's bluff"},
  };
}

/// Client side of Bluff & Brain: listens to the server-authoritative phase
/// events and exposes the write / vote / reveal state to the views.
class BluffController extends GetxController {
  final SocketService socket;
  final AuthRepository auth;

  BluffController({required this.socket, required this.auth});

  final Rx<BluffPhase> phase = BluffPhase.lobby.obs;
  final RxInt round = 0.obs;
  final RxInt totalRounds = 0.obs;
  final RxString question = ''.obs;
  final RxList<BluffOption> options = <BluffOption>[].obs;
  final RxInt fakesIn = 0.obs;
  final RxInt fakesTotal = 0.obs;
  final RxnString myFake = RxnString();
  final RxnString myVote = RxnString();
  final RxnString correctOptionId = RxnString();
  final RxMap<String, String> votes = <String, String>{}.obs;
  final RxList<BluffDelta> deltas = <BluffDelta>[].obs;
  final RxList<BluffScore> scores = <BluffScore>[].obs;
  final RxMap<String, int> powerups = <String, int>{}.obs;
  final RxSet<String> eliminated = <String>{}.obs;
  final RxString eliminatedByDetective = ''.obs;
  final RxMap<String, String> titles = <String, String>{}.obs;
  final Rxn<Map<String, dynamic>> winner = Rxn<Map<String, dynamic>>();
  final RxList<dynamic> rewards = <dynamic>[].obs;
  final RxString roast = ''.obs;
  final RxString error = ''.obs;
  final RxInt writeEndsAt = 0.obs;
  final RxInt voteEndsAt = 0.obs;
  final RxInt tick = 0.obs; // 1s ticker for countdown rings
  final TextEditingController fakeCtrl = TextEditingController();

  Timer? _ticker;
  String get myId => auth.currentUser.value?.id ?? '';

  String? playerName(String userId) {
    // Names come from the party room player list when available.
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    for (final p in BluffPowerups.all.keys) {
      powerups[p] = 1;
    }
    socket.on(SocketEvents.bluffStart, _onStart);
    socket.on(SocketEvents.bluffRound, _onRound);
    socket.on(SocketEvents.bluffFakesIn, _onFakesIn);
    socket.on(SocketEvents.bluffVotePhase, _onVotePhase);
    socket.on(SocketEvents.bluffReveal, _onReveal);
    socket.on(SocketEvents.bluffEnd, _onEnd);
    socket.on(SocketEvents.bluffPowerupResult, _onPowerupResult);
    socket.on(SocketEvents.bluffPlayerLeft, _onPlayerLeft);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
  }

  void _onStart(dynamic data) {
    try {
      final m = Map<String, dynamic>.from(data as Map);
      totalRounds.value = (m['totalRounds'] as num?)?.toInt() ?? 5;
      round.value = 0;
      phase.value = BluffPhase.lobby;
    } catch (_) {}
  }

  void _onRound(dynamic data) {
    try {
      final m = Map<String, dynamic>.from(data as Map);
      round.value = (m['round'] as num?)?.toInt() ?? 1;
      question.value = '${m['question'] ?? ''}';
      options.clear();
      myFake.value = null;
      myVote.value = null;
      correctOptionId.value = null;
      votes.clear();
      deltas.clear();
      eliminated.clear();
      eliminatedByDetective.value = '';
      roast.value = '';
      fakeCtrl.clear();
      fakesIn.value = 0;
      writeEndsAt.value = (m['writeEndsAt'] as num?)?.toInt() ?? 0;
      phase.value = BluffPhase.write;
    } catch (_) {}
  }

  void _onFakesIn(dynamic data) {
    try {
      final m = Map<String, dynamic>.from(data as Map);
      fakesIn.value = (m['count'] as num?)?.toInt() ?? 0;
      fakesTotal.value = (m['total'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  void _onVotePhase(dynamic data) {
    try {
      final m = Map<String, dynamic>.from(data as Map);
      final list = (m['options'] as List?) ?? const [];
      options.assignAll(list.map((e) {
        final o = Map<String, dynamic>.from(e as Map);
        return BluffOption(id: '${o['id']}', text: '${o['text']}');
      }));
      voteEndsAt.value = (m['voteEndsAt'] as num?)?.toInt() ?? 0;
      myVote.value = null;
      phase.value = BluffPhase.vote;
    } catch (_) {}
  }

  void _onReveal(dynamic data) {
    try {
      final m = Map<String, dynamic>.from(data as Map);
      correctOptionId.value = '${m['correctOptionId'] ?? ''}';
      final list = (m['options'] as List?) ?? const [];
      options.assignAll(list.map((e) {
        final o = Map<String, dynamic>.from(e as Map);
        return BluffOption(
          id: '${o['id']}',
          text: '${o['text']}',
          authorId: o['authorId'] == null ? null : '${o['authorId']}',
        );
      }));
      final v = (m['votes'] as Map?) ?? {};
      votes.assignAll(v.map((k, val) => MapEntry('$k', '$val')));
      final d = (m['deltas'] as List?) ?? const [];
      deltas.assignAll(d.map((e) {
        final dd = Map<String, dynamic>.from(e as Map);
        return BluffDelta(
          userId: '${dd['userId']}',
          delta: (dd['delta'] as num?)?.toInt() ?? 0,
          votedTruth: dd['votedTruth'] == true,
          fooled: (dd['fooled'] as num?)?.toInt() ?? 0,
        );
      }));
      _applyScores(m['scores']);
      // Roast the player when they missed the truth.
      final myDelta = deltas.firstWhereOrNull((e) => e.userId == myId);
      if (myDelta != null && !myDelta.votedTruth) {
        roast.value = BluffRoasts.pick();
      } else {
        roast.value = '';
      }
      phase.value = BluffPhase.reveal;
    } catch (_) {}
  }

  void _onEnd(dynamic data) {
    try {
      final m = Map<String, dynamic>.from(data as Map);
      _applyScores(m['scores']);
      final t = (m['titles'] as Map?) ?? {};
      titles.assignAll(t.map((k, v) => MapEntry('$k', '$v')));
      final w = m['winner'];
      winner.value = w is Map ? Map<String, dynamic>.from(w) : null;
      rewards.assignAll((m['rewards'] as List?) ?? const []);
      phase.value = BluffPhase.done;
    } catch (_) {}
  }

  void _onPowerupResult(dynamic data) {
    try {
      final m = Map<String, dynamic>.from(data as Map);
      if (m['type'] == 'detective') {
        final id = '${m['eliminatedOptionId'] ?? ''}';
        eliminated.add(id);
        eliminatedByDetective.value = id;
        Get.snackbar('🕵️ Detective',
            'One fake answer eliminated. Choose wisely.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {}
  }

  void _onPlayerLeft(dynamic data) {
    try {
      final m = Map<String, dynamic>.from(data as Map);
      _applyScores(m['scores']);
      Get.snackbar('Player left', 'The show goes on without them.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {}
  }

  void _applyScores(dynamic raw) {
    final list = (raw as List?) ?? const [];
    scores.assignAll(list.map((e) {
      final s = Map<String, dynamic>.from(e as Map);
      return BluffScore(
        userId: '${s['userId']}',
        score: (s['score'] as num?)?.toInt() ?? 0,
        truths: (s['truths'] as num?)?.toInt() ?? 0,
        fooled: (s['fooled'] as num?)?.toInt() ?? 0,
      );
    }));
  }

  // ---- actions ------------------------------------------------------------

  void submitFake() {
    final text = fakeCtrl.text.trim();
    if (text.isEmpty || phase.value != BluffPhase.write) return;
    myFake.value = text;
    socket.submitBluffFake(text);
  }

  void vote(String optionId) {
    if (phase.value != BluffPhase.vote || myVote.value != null) return;
    if (eliminated.contains(optionId)) return;
    myVote.value = optionId;
    socket.voteBluff(optionId);
  }

  void usePowerup(String type, {String? targetUserId}) {
    if ((powerups[type] ?? 0) <= 0) return;
    if (type == 'swap' && targetUserId == null) {
      // UI picks the target first; controller re-invoked with it.
      return;
    }
    socket.useBluffPowerup(type, targetUserId: targetUserId);
    // Optimistically consume; the server is authoritative and errors
    // surface via the global error event if the use was illegal.
    powerups[type] = 0;
    if (type == 'swap') {
      // The stolen text arrives as our fake at reveal; mark placeholder.
      myFake.value = myFake.value ?? '…';
    }
  }

  int powerupCount(String type) => powerups[type] ?? 0;

  double writeProgress() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const total = 30000;
    final remain = (writeEndsAt.value - now).clamp(0, total);
    return remain / total;
  }

  int writeSecondsLeft() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((writeEndsAt.value - now) / 1000).ceil().clamp(0, 30);
  }

  double voteProgress() {
    final now = DateTime.now().millisecondsSinceEpoch;
    const total = 20000;
    final remain = (voteEndsAt.value - now).clamp(0, total);
    return remain / total;
  }

  int voteSecondsLeft() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((voteEndsAt.value - now) / 1000).ceil().clamp(0, 20);
  }

  void leave() {
    socket.leaveRoom();
    Get.offAllNamed(Routes.home);
  }

  @override
  void onClose() {
    _ticker?.cancel();
    socket.off(SocketEvents.bluffStart);
    socket.off(SocketEvents.bluffRound);
    socket.off(SocketEvents.bluffFakesIn);
    socket.off(SocketEvents.bluffVotePhase);
    socket.off(SocketEvents.bluffReveal);
    socket.off(SocketEvents.bluffEnd);
    socket.off(SocketEvents.bluffPowerupResult);
    socket.off(SocketEvents.bluffPlayerLeft);
    fakeCtrl.dispose();
    super.onClose();
  }
}
