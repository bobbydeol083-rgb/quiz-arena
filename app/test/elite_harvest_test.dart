import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:quiz_arena/app/data/models/question.dart';
import 'package:quiz_arena/app/data/repositories/bookmark_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';
import 'package:quiz_arena/app/modules/zones/controllers/true_false_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return '/tmp/quiz_arena_elite_test';
      }
      return null;
    });
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
  });

  group('TrueFalseStatement', () {
    test('parses statement and boolean answer', () {
      final s = TrueFalseStatement.fromJson({
        'statement': 'Honey never spoils.',
        'answer': true,
      });
      expect(s.statement, 'Honey never spoils.');
      expect(s.answer, isTrue);

      final f = TrueFalseStatement.fromJson({
        'statement': 'The sky is green.',
        'answer': false,
      });
      expect(f.answer, isFalse);
    });
  });

  group('CoinLedger', () {
    test('records and returns entries newest-first', () async {
      final ledger = CoinLedger();
      await ledger.record(50, 'Daily scratch reward');
      await ledger.record(100, 'Referral bonus');

      final entries = ledger.entries();
      expect(entries.length, 2);
      expect(entries.first.amount, 100);
      expect(entries.first.reason, 'Referral bonus');
      expect(entries.last.amount, 50);
    });

    test('round-trips through JSON', () {
      final stamp = DateTime(2026, 10, 3, 6, 30);
      final e = CoinEntry.fromJson(
          CoinEntry(amount: 20, reason: 'True/False zone', at: stamp)
              .toJson());
      expect(e.amount, 20);
      expect(e.reason, 'True/False zone');
      expect(e.at, stamp);
    });
  });

  group('BookmarkRepository', () {
    Question q(String id) => Question(
          id: id,
          category: 'Science',
          difficulty: 'easy',
          question: 'Is water wet?',
          options: const ['Yes', 'No', 'Maybe', 'H2O'],
          answerIndex: 0,
        );

    test('toggle adds and removes', () async {
      final repo = BookmarkRepository();
      expect(repo.isBookmarked('q1'), isFalse);

      await repo.toggle(q('q1'));
      expect(repo.isBookmarked('q1'), isTrue);
      expect(repo.all().length, 1);

      await repo.toggle(q('q1'));
      expect(repo.isBookmarked('q1'), isFalse);
      expect(repo.all(), isEmpty);
    });
  });
}
