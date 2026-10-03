import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';

/// Standalone statistics screen state.
class StatisticsController extends GetxController {
  final ProgressRepository progress;
  final AuthRepository auth;

  StatisticsController({required this.progress, required this.auth});

  double get accuracy {
    final p = progress.progress.value;
    if (p.totalAnswered == 0) return 0;
    return p.totalCorrect / p.totalAnswered;
  }

  double get winRate {
    final p = progress.progress.value;
    if (p.totalQuizzes == 0) return 0;
    return p.wins / p.totalQuizzes;
  }
}
