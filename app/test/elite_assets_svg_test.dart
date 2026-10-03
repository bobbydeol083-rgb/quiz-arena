import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Every SVG harvested from Elite Quiz must render via flutter_svg.
void main() {
  testWidgets('all elite SVGs render', (tester) async {
    final dir = Directory('assets/elite');
    final svgs =
        dir.listSync().where((f) => f.path.endsWith('.svg')).toList();
    expect(svgs.length, greaterThan(30));

    for (final f in svgs) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgPicture.asset(f.path),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byType(SvgPicture),
        findsOneWidget,
        reason: 'failed to render ${f.path}',
      );
    }
  }, skip: false);
}
