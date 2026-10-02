import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/question.dart';

/// Bundled offline question bank (`assets/questions.json`).
///
/// Used whenever the backend is unreachable: the app keeps working fully
/// offline (solo/blitz/marathon/daily) and grades locally via the embedded
/// `answerIndex`.
class LocalQuestionBank extends GetxService {
  static const String assetPath = 'assets/questions.json';

  List<Question>? _cache;

  Future<List<Question>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(assetPath);
    final list = jsonDecode(raw) as List;
    _cache =
        list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }

  /// Total bundled questions (useful for diagnostics / tests).
  Future<int> count() async => (await _load()).length;

  /// Pick [count] questions, optionally filtered. Difficulty ramps are
  /// supported by passing [difficulties] (e.g. marathon progression).
  Future<List<Question>> pick({
    String? categoryId,
    String? difficulty,
    List<String>? difficulties,
    int count = 10,
    int? seed,
  }) async {
    final all = await _load();
    final rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

    List<Question> pool = all;
    if (categoryId != null && categoryId.isNotEmpty) {
      pool = pool
          .where((q) => q.category.toLowerCase() == categoryId.toLowerCase())
          .toList();
    }
    if (difficulties != null && difficulties.isNotEmpty) {
      final out = <Question>[];
      final perBucket = (count / difficulties.length).ceil();
      for (final d in difficulties) {
        final bucket =
            pool.where((q) => q.difficulty == d).toList()..shuffle(rng);
        out.addAll(bucket.take(perBucket));
      }
      out.shuffle(rng);
      return out.take(count).toList();
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      final filtered =
          pool.where((q) => q.difficulty == difficulty).toList();
      if (filtered.isNotEmpty) pool = filtered;
    }
    pool = List<Question>.from(pool)..shuffle(rng);
    if (pool.length < count) {
      // Not enough in the filtered pool — top up from the full bank.
      final rest = List<Question>.from(all)..shuffle(rng);
      final ids = pool.map((q) => q.id).toSet();
      for (final q in rest) {
        if (pool.length >= count) break;
        if (ids.add(q.id)) pool.add(q);
      }
    }
    return pool.take(count).toList();
  }

  /// Deterministic set for the daily challenge — same for every player on
  /// the same calendar day (used as the offline fallback).
  Future<List<Question>> dailySet({int count = 10, DateTime? date}) async {
    final day = date ?? DateTime.now();
    final seed = day.year * 10000 + day.month * 100 + day.day;
    return pick(count: count, seed: seed);
  }

  /// For unit tests: inject questions without touching the asset bundle.
  void debugSeed(List<Question> questions) {
    _cache = questions;
  }
}
