import 'package:get_storage/get_storage.dart';

import 'package:quiz_arena/app/data/models/question.dart';

/// Bookmarked questions, persisted locally for review.
class BookmarkRepository {
  static const String _key = 'bookmarks_v1';
  static const int _max = 200;

  final GetStorage box;

  BookmarkRepository({GetStorage? box}) : box = box ?? GetStorage();

  List<Question> all() {
    final raw = box.read<List>(_key);
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Question.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  bool isBookmarked(String id) =>
      box.read<List>(_key)?.any((m) =>
          m is Map && '${(m)['id'] ?? ''}' == id) ??
      false;

  Future<void> toggle(Question q) async {
    final list = all().toList();
    final i = list.indexWhere((e) => e.id == q.id);
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.insert(0, q);
    }
    await box.write(
        _key, list.take(_max).map((e) => e.toJson()).toList());
  }
}
