import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../values/app_values.dart';
import 'background.dart';

/// App shell: ambient background + optional app bar + animated bottom nav.
///
/// The 4 tabs are Home(0), Discover(1), Leaderboard(2), Profile(3) with a
/// center "Play" FAB that opens the mode picker. Tab switches use
/// [Get.offNamed] so each screen stays a decoupled module; the active pill
/// *slides* from the previous tab via a remembered static index.
class ArenaScaffold extends StatefulWidget {
  final int currentIndex;
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? floatingActionButton;

  const ArenaScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.title,
    this.actions,
    this.showBack = false,
    this.floatingActionButton,
  });

  @override
  State<ArenaScaffold> createState() => _ArenaScaffoldState();
}

class _ArenaScaffoldState extends State<ArenaScaffold>
    with SingleTickerProviderStateMixin {
  /// Remembers the last tab across route swaps so the pill can slide.
  static int _lastIndex = 0;

  late final AnimationController _pillController;
  late final Animation<double> _pillSlide;

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pillSlide = Tween<double>(
      begin: _lastIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(
      CurvedAnimation(parent: _pillController, curve: Curves.easeOutCubic),
    );
    _lastIndex = widget.currentIndex;
    _pillController.forward();
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  static const _tabs = [
    _Tab(Routes.home, Icons.home_rounded, 'Home'),
    _Tab(Routes.discover, Icons.explore_rounded, 'Discover'),
    _Tab(Routes.leaderboard, Icons.leaderboard_rounded, 'Ranks'),
    _Tab(Routes.profile, Icons.person_rounded, 'Profile'),
  ];

  /// Tab index -> slot index in the 5-slot bar (center slot is the FAB).
  /// Kept as documentation of the layout; the pill position is computed
  /// by [_BottomBar._lerpSlot].
  void _go(int tab) {
    if (tab == widget.currentIndex) return;
    Get.offNamed(_tabs[tab].route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: widget.title == null && !widget.showBack
          ? null
          : AppBar(
              title: widget.title == null ? null : Text(widget.title!),
              leading: widget.showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Get.back(),
                    )
                  : null,
              actions: widget.actions,
            ),
      body: ArenaBackground(
        child: SafeArea(
          bottom: false,
          child: widget.body,
        ),
      ),
      floatingActionButton: widget.floatingActionButton ??
          _PlayFab(onTap: () => Get.toNamed(Routes.modes)),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        currentIndex: widget.currentIndex,
        pillSlide: _pillSlide,
        onTap: _go,
        isDark: isDark,
      ),
    );
  }
}

class _Tab {
  final String route;
  final IconData icon;
  final String label;
  const _Tab(this.route, this.icon, this.label);
}

class _PlayFab extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayFab({required this.onTap});

  @override
  State<_PlayFab> createState() => _PlayFabState();
}

class _PlayFabState extends State<_PlayFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final Animation<double> pillSlide;
  final void Function(int tab) onTap;
  final bool isDark;

  const _BottomBar({
    required this.currentIndex,
    required this.pillSlide,
    required this.onTap,
    required this.isDark,
  });

  /// Map a fractional tab value to a fractional 5-slot position,
  /// skipping the center FAB slot (slot 2).
  double _lerpSlot(double tabValue) {
    final lo = tabValue.floor().clamp(0, 3);
    final hi = tabValue.ceil().clamp(0, 3);
    final t = tabValue - lo;
    double slotOf(int tab) => (tab < 2 ? tab : tab + 1).toDouble();
    return slotOf(lo) + (slotOf(hi) - slotOf(lo)) * t;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorder
              : AppColors.violetDeep.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotW = constraints.maxWidth / 5;
            const pillW = 56.0;
            return SizedBox(
              height: 72,
              child: Stack(
                children: [
                  // Sliding active pill.
                  AnimatedBuilder(
                    animation: pillSlide,
                    builder: (context, _) {
                      final animSlot = _lerpSlot(pillSlide.value);
                      final left = animSlot * slotW + (slotW - pillW) / 2;
                      return Positioned(
                        left: left,
                        top: 12,
                        child: Container(
                          width: pillW,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.violet
                                    .withValues(alpha: 0.5),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      for (var tab = 0; tab < 4; tab++) ...[
                        _navItem(context, tab, slotW,
                            active: tab == currentIndex),
                        if (tab == 1) SizedBox(width: slotW), // FAB slot
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int tab, double slotW,
      {required bool active}) {
    const tabs = [
      _Tab(Routes.home, Icons.home_rounded, 'Home'),
      _Tab(Routes.discover, Icons.explore_rounded, 'Discover'),
      _Tab(Routes.leaderboard, Icons.leaderboard_rounded, 'Ranks'),
      _Tab(Routes.profile, Icons.person_rounded, 'Profile'),
    ];
    final t = tabs[tab];
    final color = active
        ? Colors.white
        : (isDark ? AppColors.adaptiveMuted : AppColors.lightTextSecondary);
    return SizedBox(
      width: slotW,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(tab),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Icon(t.icon, color: color, size: 24),
              ),
              const SizedBox(height: 2),
              Text(
                t.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient-ring avatar with initials fallback.
class ArenaAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const ArenaAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p.characters.first.toUpperCase())
            .join();
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(initials),
              )
            : _fallback(initials),
      ),
    );
  }

  Widget _fallback(String initials) => Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: AppGradients.primaryVertical,
        ),
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      );
}

/// Friendly empty state.
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: AppInsets.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark
                    ? AppColors.adaptiveSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
