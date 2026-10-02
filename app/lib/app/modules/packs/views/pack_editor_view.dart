import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/values/app_values.dart';
import 'package:quiz_arena/app/core/widgets/widgets.dart';

import '../controllers/pack_editor_controller.dart';

/// Author a new game pack: metadata + 5–50 questions.
class PackEditorView extends GetView<PackEditorController> {
  const PackEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: ArenaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: AppInsets.screen,
                child: Row(
                  children: [
                    ArenaIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: Get.back,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('New game pack',
                        style: text.headlineSmall),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppInsets.screen,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _field('Title', controller.titleCtrl,
                          hint: 'e.g. Desi Pop Culture'),
                      _field('Description',
                          controller.descCtrl,
                          hint: 'What is this pack about?',
                          maxLines: 2),
                      _field('Label', controller.labelCtrl,
                          hint: 'e.g. Fake Facts'),
                      Text('Game mode', style: text.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(
                        () => Row(
                          children: [
                            ChoiceChip(
                              label: const Text('🧠 Quiz'),
                              selected:
                                  controller.mode.value ==
                                      'quiz',
                              onSelected: (_) => controller
                                  .mode.value = 'quiz',
                            ),
                            const SizedBox(
                                width: AppSpacing.sm),
                            ChoiceChip(
                              label:
                                  const Text('🎭 Bluff & Brain'),
                              selected:
                                  controller.mode.value ==
                                      'bluff',
                              onSelected: (_) => controller
                                  .mode.value = 'bluff',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Text(
                            'Questions (${controller.questions.length})',
                            style: text.titleMedium,
                          ),
                          const Spacer(),
                          GhostButton(
                            label: '+ Add',
                            onPressed: controller.addQuestion,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Obx(
                        () => Column(
                          children: List.generate(
                            controller.questions.length,
                            (i) => _questionCard(
                                text, i, context),
                          ),
                        ),
                      ),
                      Obx(
                        () => controller.error.value.isEmpty
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                    top: AppSpacing.sm),
                                child: Text(
                                  controller.error.value,
                                  style: text.bodyMedium
                                      ?.copyWith(
                                          color: Colors
                                              .redAccent),
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Obx(
                        () => GradientButton(
                          label: controller.saving.value
                              ? 'Saving…'
                              : 'Save draft',
                          onPressed: controller.saving.value
                              ? () {}
                              : () =>
                                  controller.save(
                                      publish: false),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Obx(
                        () => GhostButton(
                          label: 'Save & publish',
                          onPressed: controller.saving.value
                              ? () {}
                              : () =>
                                  controller.save(
                                      publish: true),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(
      TextTheme text, int index, BuildContext context) {
    final draft = controller.questions[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Q${index + 1}',
                      style: text.titleSmall),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20),
                    onPressed: () =>
                        controller.removeQuestion(index),
                  ),
                ],
              ),
              TextField(
                controller: draft.question,
                decoration: const InputDecoration(
                    hintText: 'Question text'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...List.generate(4, (o) {
                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppSpacing.xs),
                  child: Row(
                    children: [
                      Obx(
                        () => Radio<int>(
                          value: o,
                          groupValue:
                              draft.answerIndex.value,
                          onChanged: (v) =>
                              draft.answerIndex.value =
                                  v ?? 0,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: draft.options[o],
                          decoration: InputDecoration(
                            hintText:
                                'Option ${o + 1} (radio = correct)',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.sm),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              TextField(
                controller: draft.explanation,
                decoration: const InputDecoration(
                    hintText: 'Explanation (optional)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
