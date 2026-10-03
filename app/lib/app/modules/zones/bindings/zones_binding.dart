import 'package:get/get.dart';

import 'package:quiz_arena/app/data/providers/local_question_bank.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';
import 'package:quiz_arena/app/data/services/coin_ledger.dart';

import '../controllers/true_false_controller.dart';
import '../controllers/exam_controller.dart';

class TrueFalseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrueFalseController>(
      () => TrueFalseController(
        auth: Get.find<AuthRepository>(),
        progress: Get.find<ProgressRepository>(),
        ledger: Get.find<CoinLedger>(),
      ),
    );
  }
}

class ExamBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExamController>(
      () => ExamController(
        bank: Get.find<LocalQuestionBank>(),
        auth: Get.find<AuthRepository>(),
        progress: Get.find<ProgressRepository>(),
        ledger: Get.find<CoinLedger>(),
      ),
    );
  }
}
