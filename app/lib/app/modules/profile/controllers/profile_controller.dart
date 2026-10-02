import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:quiz_arena/app/core/utils/badge_service.dart';
import 'package:quiz_arena/app/data/models/models.dart';
import 'package:quiz_arena/app/data/repositories/auth_repository.dart';
import 'package:quiz_arena/app/data/repositories/progress_repository.dart';

/// Profile state: current user, local progress stats, badge shelf and the
/// 3-tab controller (Badges / Stats / Details).
class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AuthRepository auth;
  final ProgressRepository progressRepo;
  final BadgeService badgeService;

  ProfileController({
    required this.auth,
    required this.progressRepo,
    required this.badgeService,
  });

  late final TabController tabController;

  AppUser? get user => auth.currentUser.value;
  PlayerProgress get progress => progressRepo.progress.value;
  List<Badge> get badges => Badge.shelf(badgeService.unlocked.toSet());

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
