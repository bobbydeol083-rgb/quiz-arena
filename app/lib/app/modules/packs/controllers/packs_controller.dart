import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/repositories/pack_repository.dart';
import 'package:quiz_arena/app/modules/quiz/controllers/quiz_controller.dart';
import 'package:quiz_arena/app/routes/app_routes.dart';

/// Game Packs: browse community packs, install them for offline play,
/// publish your own, and play installed packs in solo mode.
class PacksController extends GetxController {
  final PackRepository packs;

  PacksController({required this.packs});

  final RxInt tab = 0.obs; // 0 browse, 1 installed, 2 mine
  final RxBool isLoading = false.obs;
  final RxList<GamePack> browsePacks = <GamePack>[].obs;
  final RxList<GamePackDetail> installed = <GamePackDetail>[].obs;
  final RxList<GamePack> mine = <GamePack>[].obs;
  final RxString search = ''.obs;
  final RxString modeFilter = ''.obs; // '' | 'quiz' | 'bluff'
  final RxString sort = 'popular'.obs;
  final RxString error = ''.obs;
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    refreshAll();
    debounce(
      search,
      (_) => refreshBrowse(),
      time: const Duration(milliseconds: 500),
    );
  }

  Future<void> refreshAll() async {
    await Future.wait([refreshBrowse(), refreshInstalled(), refreshMine()]);
  }

  Future<void> refreshBrowse() async {
    isLoading.value = true;
    error.value = '';
    try {
      browsePacks.assignAll(
        await packs.browse(
          search: search.value.isEmpty ? null : search.value,
          mode: modeFilter.value.isEmpty ? null : modeFilter.value,
          sort: sort.value,
        ),
      );
    } catch (e) {
      error.value = 'Could not load packs. Pull to retry.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshInstalled() async {
    installed.assignAll(packs.installedPacks());
  }

  Future<void> refreshMine() async {
    try {
      mine.assignAll(await packs.myPacks());
    } catch (_) {
      // Guests / offline: leave empty.
    }
  }

  bool isInstalled(String id) => installed.any((p) => p.id == id);

  Future<void> install(GamePack pack) async {
    try {
      final detail = await packs.install(pack.id);
      await refreshInstalled();
      Get.snackbar(
        'Installed',
        '"${detail.title}" is ready — even offline.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Install failed', 'Check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> uninstall(String id) async {
    await packs.uninstall(id);
    await refreshInstalled();
  }

  /// Play an installed pack as a solo quiz. Questions carry answers locally
  /// (install payload), so grading works offline via QuizEngine.
  void playPack(GamePackDetail detail) {
    final questions = detail.questions
        .where((q) => q.answerIndex != null)
        .map(
          (q) => Question(
            id: 'pack:${detail.id}:${detail.questions.indexOf(q)}',
            category: detail.label,
            difficulty: 'medium',
            question: q.question,
            options: q.options,
            answerIndex: q.answerIndex,
            explanation: q.explanation,
          ),
        )
        .toList();
    if (questions.isEmpty) {
      Get.snackbar('Empty pack', 'This pack has no playable questions.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    packs.markPlayed(detail.id);
    Get.toNamed(
      Routes.quiz,
      arguments: QuizArgs(
        mode: QuizMode.solo,
        questions: questions,
        packId: detail.id,
      ),
    );
  }

  Future<void> publish(String id) async {
    try {
      await packs.publish(id);
      await refreshAll();
      Get.snackbar('Published', 'Your pack is live for everyone.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Publish failed', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> unpublish(String id) async {
    try {
      await packs.unpublish(id);
      await refreshAll();
    } catch (e) {
      Get.snackbar('Failed', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deletePack(String id) async {
    try {
      await packs.delete(id);
      await refreshAll();
    } catch (e) {
      Get.snackbar('Delete failed', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
