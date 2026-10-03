import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:quiz_arena/app/core/theme/elite_theme.dart';
import 'package:quiz_arena/app/core/theme/elite_widgets.dart';
import 'package:quiz_arena/app/core/values/elite_assets.dart';
import 'package:quiz_arena/app/data/repositories/bookmark_repository.dart';

/// Saved questions for later review — Elite Quiz UI: pink index chips,
/// white cards, remove buttons, "Review Bookmarks" CTA pinned at bottom.
class BookmarksView extends StatelessWidget {
  const BookmarksView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<BookmarkRepository>();
    return Scaffold(
      backgroundColor: EliteTheme.pageBg,
      appBar: const EliteAppBar(title: 'Bookmarks'),
      body: _BookmarksList(repo: repo),
    );
  }
}

class _BookmarksList extends StatefulWidget {
  final BookmarkRepository repo;
  const _BookmarksList({required this.repo});

  @override
  State<_BookmarksList> createState() => _BookmarksListState();
}

class _BookmarksListState extends State<_BookmarksList> {
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final items = widget.repo.all();
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(EliteAssets.bookmark,
                  width: 88, height: 88),
              const SizedBox(height: 20),
              Text('No bookmarks yet',
                  style: eliteText(size: 22, weight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Tap the bookmark icon during a quiz\nto save tricky questions here.',
                style: eliteText(size: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 16, 16, h * 0.12),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final q = items[i];
            final answer = q.answerIndex != null &&
                    q.answerIndex! >= 0 &&
                    q.answerIndex! < q.options.length
                ? q.options[q.answerIndex!]
                : null;
            return GestureDetector(
              onTap: () => _showDetail(context, i, q.question,
                  answer, q.explanation),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    /// Pink index chip
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD7E5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: eliteText(
                            size: 16,
                            weight: FontWeight.bold,
                            color: EliteTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: eliteText(
                            size: 16, weight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),

                    /// Remove button
                    GestureDetector(
                      onTap: () async {
                        await widget.repo.toggle(q);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: EliteTheme.pageBg, width: 2),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: EliteTheme.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        /// Review CTA pinned at bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: EliteButton(
              title: 'Review Bookmarks',
              onTap: () {
                if (items.isNotEmpty) {
                  _showDetail(context, 0, items.first.question,
                      _answerOf(items.first), items.first.explanation);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  String? _answerOf(q) {
    return q.answerIndex != null &&
            q.answerIndex! >= 0 &&
            q.answerIndex! < q.options.length
        ? q.options[q.answerIndex!]
        : null;
  }

  void _showDetail(BuildContext context, int index, String question,
      String? answer, String? explanation) {
    final h = MediaQuery.of(context).size.height;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        height: h * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Bookmark ${index + 1}',
                style:
                    eliteText(size: 18, weight: FontWeight.bold)),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(question,
                        textAlign: TextAlign.center,
                        style: eliteText(size: 18)),
                    if (answer != null) ...[
                      const SizedBox(height: 16),
                      Text('Answer: $answer',
                          style: eliteText(
                              size: 16,
                              weight: FontWeight.bold,
                              color: EliteTheme.correct)),
                    ],
                    if (explanation?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(explanation!,
                          textAlign: TextAlign.center,
                          style: eliteText(size: 14)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
