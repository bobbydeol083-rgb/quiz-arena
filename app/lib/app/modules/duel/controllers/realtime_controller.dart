import 'package:get/get.dart';

import '../../../data/models/models.dart';
import '../../../data/providers/socket_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';
import '../../quiz/controllers/quiz_controller.dart';
import '../views/widgets/duel_invite_dialog.dart';

/// Permanent realtime listener (registered in [InitialBinding]).
///
/// Handles global socket events no matter which screen is showing:
/// - `duel:invited`  -> incoming duel invite dialog (accept / decline)
/// - `duel:accepted` -> our invite was accepted (game:start follows)
/// - `game:start`    -> both players receive the same questions -> open quiz
///
/// Module controllers (duel lobby, party room, nearby) handle their own
/// scoped flows; this service only handles app-wide events.
class RealtimeController extends GetxService {
  final SocketService socket;
  final AuthRepository auth;

  RealtimeController({required this.socket, required this.auth});

  /// Opponent identity stashed before `game:start` arrives (the server's
  /// game:start payload carries no opponent). Set from `match:found`,
  /// `duel:invited` (invitee side), or explicitly by the inviter.
  String? _pendingOpponentName;
  String? _pendingOpponentId;

  /// Called by the invite sender (e.g. nearby list) which knows the target.
  void setPendingOpponent({String? name, String? id}) {
    _pendingOpponentName = name;
    _pendingOpponentId = id;
  }

  @override
  void onInit() {
    super.onInit();
    socket.on(SocketEvents.duelInvited, _onDuelInvited);
    socket.on(SocketEvents.duelAccepted, _onDuelAccepted);
    socket.on(SocketEvents.matchFound, _onMatchFound);
    socket.on(SocketEvents.gameStart, _onGameStart);
    socket.on(SocketEvents.bluffStart, _onBluffStart);
  }

  void _onMatchFound(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final opp = map['opponent'];
      if (opp is Map) {
        final o = Map<String, dynamic>.from(opp);
        setPendingOpponent(
          name: '${o['username'] ?? 'Opponent'}',
          id: '${o['id'] ?? o['userId'] ?? ''}',
        );
      }
    } catch (_) {}
  }

  void _onDuelInvited(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final inviteId = '${map['inviteId'] ?? ''}';
      if (inviteId.isEmpty) return;
      final from = map['from'];
      final fromMap = from is Map ? Map<String, dynamic>.from(from) : {};
      // Remember the inviter: game:start carries no opponent payload.
      setPendingOpponent(
        name: '${fromMap['username'] ?? 'A player'}',
        id: '${fromMap['id'] ?? fromMap['userId'] ?? ''}',
      );
      Get.dialog(
        DuelInviteDialog(
          inviteId: inviteId,
          fromName: _pendingOpponentName ?? 'A player',
          fromAvatar: fromMap['avatar'] as String?,
          category: _inviteCategoryName(map['category']),
        ),
        barrierDismissible: false,
      );
    } catch (_) {}
  }

  /// The server sends `category` as an object ({id,name,icon,color}) or null.
  static String _inviteCategoryName(dynamic category) {
    if (category is Map) {
      final name = category['name'];
      if (name != null && '$name'.isNotEmpty) return '$name';
    } else if (category is String && category.isNotEmpty) {
      return category;
    }
    return 'Mixed';
  }

  void _onDuelAccepted(dynamic data) {
    if (Get.isDialogOpen == true) Get.back();
    Get.snackbar(
      'Duel accepted',
      'Your opponent is ready — the battle starts soon…',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _onGameStart(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final questions = ((map['questions'] as List?) ?? [])
          .map((e) => Question.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (questions.isEmpty) return;
      if (Get.currentRoute == Routes.quiz) return;

      String? oppName;
      String? oppId;
      final opp = map['opponent'];
      if (opp is Map) {
        final o = Map<String, dynamic>.from(opp);
        oppName = '${o['username'] ?? 'Opponent'}';
        oppId = '${o['id'] ?? o['userId'] ?? ''}';
      }
      // Fall back to the identity stashed from match:found / duel:invited /
      // the explicit invite sender — the server's game:start has no opponent.
      oppName ??= _pendingOpponentName;
      oppId ??= _pendingOpponentId;
      _pendingOpponentName = null;
      _pendingOpponentId = null;
      // The server tags party games as mode 'room'; everything else realtime
      // is a duel.
      final quizMode =
          '${map['mode'] ?? ''}' == 'room' ? QuizMode.party : QuizMode.duel;
      Get.toNamed(
        Routes.quiz,
        arguments: QuizArgs(
          mode: quizMode,
          questions: questions,
          roomId: map['roomId'] as String?,
          opponentName: oppName,
          opponentId: oppId,
        ),
      );
    } catch (_) {}
  }

  /// Bluff & Brain: the host's room:start deals bluff rounds instead of a
  /// classic game. Open the bluff table for every player in the room.
  void _onBluffStart(dynamic data) {
    try {
      if (Get.currentRoute == Routes.bluff) return;
      Get.toNamed(Routes.bluff);
    } catch (_) {}
  }
}
