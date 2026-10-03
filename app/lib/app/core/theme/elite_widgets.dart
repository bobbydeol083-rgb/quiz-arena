import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_arena/app/core/theme/elite_theme.dart';

/// Shared Elite Quiz UI primitives — ported from Elite v2.3.7's
/// custom_appbar.dart, custom_rounded_button.dart and statistics pie chart.
/// Nunito everywhere, Elite pink, rounded-bottom app bar.

TextStyle eliteText({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = EliteTheme.primaryText,
  double? height,
}) {
  if (EliteTheme.useSystemFont) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFamily: 'Roboto',
    );
  }
  return GoogleFonts.nunito(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

/// Elite QAppBar: white bg, rounded bottom corners, centered bold title.
class EliteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool rounded;
  final Color backgroundColor;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const EliteAppBar({
    super.key,
    required this.title,
    this.rounded = true,
    this.backgroundColor = Colors.white,
    this.leading,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      backgroundColor: backgroundColor,
      shape: rounded
          ? const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(10)),
            )
          : null,
      leading: leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: EliteTheme.primaryText),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
      title: Text(
        title,
        style: eliteText(
            size: 18,
            weight: FontWeight.bold,
            color: EliteTheme.primaryText),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// Elite CustomRoundedButton: full-width pink CTA.
class EliteButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final double widthFactor;
  final double height;
  final double radius;
  final Color backgroundColor;
  final Color titleColor;
  final double textSize;
  final FontWeight fontWeight;
  final double elevation;

  const EliteButton({
    super.key,
    required this.title,
    required this.onTap,
    this.widthFactor = 0.9,
    this.height = 58,
    this.radius = 8,
    this.backgroundColor = EliteTheme.primary,
    this.titleColor = Colors.white,
    this.textSize = 18,
    this.fontWeight = FontWeight.w600,
    this.elevation = 6.5,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width * widthFactor,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: elevation > 0
                ? [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: eliteText(
              size: textSize,
              weight: fontWeight,
              color: titleColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Elite statistics pie chart (CustomPainter, square caps, starts at top).
class ElitePieChart extends StatelessWidget {
  final List<double> fractions; // sum to 1
  final List<Color> colors;
  final double size;
  final Widget? center;

  const ElitePieChart({
    super.key,
    required this.fractions,
    required this.colors,
    this.size = 82,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _PiePainter(fractions: fractions, colors: colors),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;

  _PiePainter({required this.fractions, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (fractions.isEmpty || fractions.every((f) => f <= 0)) {
      canvas.drawArc(
        rect.deflate(4),
        0,
        3.14159 * 2,
        false,
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8,
      );
      return;
    }
    var start = -3.14159 / 2; // top
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * 3.14159 * 2;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect.deflate(4),
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.square,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.fractions != fractions || old.colors != colors;
}

/// Elite white card with soft shadow (statistics style).
class EliteCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? height;

  const EliteCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(2.5, 2.5),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Legend row with color dot (statistics style).
class EliteLegendRow extends StatelessWidget {
  final Color dot;
  final String label;
  final String value;

  const EliteLegendRow({
    super.key,
    required this.dot,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: eliteText(
                  size: 18,
                  color: EliteTheme.primaryText.withValues(alpha: 0.75))),
          const Spacer(),
          Text(value,
              style: eliteText(
                  size: 16,
                  weight: FontWeight.bold,
                  color: EliteTheme.primaryText)),
        ],
      ),
    );
  }
}
