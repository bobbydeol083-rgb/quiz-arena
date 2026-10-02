import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/data/repositories/pack_repository.dart';

/// One question being authored in the pack editor.
class PackQuestionDraft {
  final TextEditingController question = TextEditingController();
  final List<TextEditingController> options =
      List.generate(4, (_) => TextEditingController());
  final RxInt answerIndex = 0.obs;
  final TextEditingController explanation = TextEditingController();

  void dispose() {
    question.dispose();
    explanation.dispose();
    for (final c in options) {
      c.dispose();
    }
  }

  String? validate(int index) {
    if (question.text.trim().isEmpty) return 'Question ${index + 1}: text is empty';
    for (var i = 0; i < 4; i++) {
      if (options[i].text.trim().isEmpty) {
        return 'Question ${index + 1}: option ${i + 1} is empty';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'question': question.text.trim(),
        'options': options.map((c) => c.text.trim()).toList(),
        'answerIndex': answerIndex.value,
        'explanation': explanation.text.trim(),
      };
}

/// Authoring flow for a new game pack: metadata + 5–50 questions.
class PackEditorController extends GetxController {
  final PackRepository packs;

  PackEditorController({required this.packs});

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController labelCtrl = TextEditingController();
  final RxString mode = 'quiz'.obs;
  final RxList<PackQuestionDraft> questions = <PackQuestionDraft>[].obs;
  final RxBool saving = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Start with the minimum viable pack.
    for (var i = 0; i < 5; i++) {
      addQuestion();
    }
  }

  void addQuestion() {
    if (questions.length >= 50) return;
    questions.add(PackQuestionDraft());
  }

  void removeQuestion(int index) {
    if (questions.length <= 5) {
      Get.snackbar('Minimum 5', 'A pack needs at least 5 questions.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    questions[index].dispose();
    questions.removeAt(index);
  }

  Future<void> save({required bool publish}) async {
    error.value = '';
    if (titleCtrl.text.trim().length < 3) {
      error.value = 'Give your pack a title (min 3 characters).';
      return;
    }
    for (var i = 0; i < questions.length; i++) {
      final err = questions[i].validate(i);
      if (err != null) {
        error.value = err;
        return;
      }
    }
    saving.value = true;
    try {
      final detail = await packs.create(
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        label: labelCtrl.text.trim().isEmpty ? 'Custom' : labelCtrl.text.trim(),
        mode: mode.value,
        questions: questions.map((q) => q.toJson()).toList(),
      );
      if (publish) {
        await packs.publish(detail.id);
      }
      Get.back(result: true);
      Get.snackbar(
        publish ? 'Published' : 'Draft saved',
        publish
            ? '"${detail.title}" is live for everyone.'
            : '"${detail.title}" saved as a draft.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = 'Could not save: $e';
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    labelCtrl.dispose();
    for (final q in questions) {
      q.dispose();
    }
    super.onClose();
  }
}
