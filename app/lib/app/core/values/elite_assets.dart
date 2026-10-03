import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Typed access to the harvested Elite Quiz asset pack.
///
/// All SVGs render through flutter_svg; Lottie files through lottie;
/// PNGs through Image.asset.
class EliteAssets {
  EliteAssets._();

  static const String _base = 'assets/elite';

  // ---- Coins & wallet -------------------------------------------------------
  static const String coin = '$_base/coin.svg';
  static const String coinsDialog = '$_base/coins_dialog_icon.svg';
  static const String dailyCoins = '$_base/daily_coins.svg';
  static const String earnedCoin = '$_base/earnedCoin.svg';
  static const String coinStore = '$_base/coin_store.svg';
  static const String wallet = '$_base/wallet_icon.svg';
  static const String coinHistory = '$_base/coin_history_icon.svg';

  // ---- Ranks & badges ---------------------------------------------------------
  static const String rank1 = '$_base/rank_1.svg';
  static const String rank2 = '$_base/rank_2.svg';
  static const String rank3 = '$_base/rank_3.svg';
  static const String rank4 = '$_base/rank_4.svg';
  static const String badges = '$_base/badges_icon.svg';
  static const String score = '$_base/score.svg';
  static const String statistics = '$_base/statistics_icon.svg';

  // ---- Quiz zones ---------------------------------------------------------------
  static const String trueFalse = '$_base/true_false_icon.svg';
  static const String exam = '$_base/exam_icon.svg';
  static const String fun = '$_base/fun_icon.svg';
  static const String guess = '$_base/guess_icon.svg';
  static const String maths = '$_base/maths_icon.svg';
  static const String dailyQuiz = '$_base/daily_quiz_icon.svg';
  static const String selfChallenge = '$_base/self_challenge.svg';
  static const String howToPlay = '$_base/how_to_play_icon.svg';

  // ---- Lifelines ------------------------------------------------------------------
  static const String lifelineFifty = '$_base/lifeline_fiftyfifty.svg';
  static const String lifelinePoll = '$_base/lifeline_audiencepoll.svg';
  static const String lifelineSkip = '$_base/lifeline_skip.svg';
  static const String lifelineTime = '$_base/lifeline_resettime.svg';

  // ---- Social -----------------------------------------------------------------------
  static const String referEarn = '$_base/refer_earn.svg';
  static const String inviteFriends = '$_base/invite_friends.svg';
  static const String share = '$_base/share_icon.svg';
  static const String friend = '$_base/friend.svg';

  // ---- Battle -------------------------------------------------------------------------
  static const String versus = '$_base/versus.svg';
  static const String vs = '$_base/vs.svg';
  static const String vsIcon = '$_base/vs_icon.png';
  static const String groupBattle = '$_base/group_battle_icon.svg';
  static const String oneVsOne = '$_base/one_vs_one_icon.svg';

  // ---- Rewards --------------------------------------------------------------------------
  static const String rewardConfetti = '$_base/reward_confetti.svg';
  static const String scratchCover = '$_base/scratchCardCover.png';
  static const String successLottie = '$_base/success.json';
  static const String defeatLottie = '$_base/defeats.json';

  // ---- Misc -----------------------------------------------------------------------------
  static const String bookmark = '$_base/bookmark.svg';
  static const String notification = '$_base/notification_icon.svg';
  static const String settings = '$_base/settings.svg';
  static const String theme = '$_base/theme_icon.svg';
  static const String correct = '$_base/correct.svg';
  static const String wrong = '$_base/wrong.svg';
  static const String onboardingA = '$_base/onboarding_a.svg';
  static const String onboardingB = '$_base/onboarding_b.svg';
  static const String onboardingC = '$_base/onboarding_c.svg';

  /// Small helper: an SVG asset as a sized widget.
  static Widget svg(String path,
      {double size = 24, Color? color, BoxFit fit = BoxFit.contain}) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      fit: fit,
      colorFilter:
          color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
