import 'package:flutter/material.dart';

/// Cream-paper design tokens (code-rendered — CONTEXT says do NOT use images).
const Color kPaperCream = Color(0xFFFFF8E7);
const Color kRuledLine = Color(0xFFE8E0D4);
const Color kMargin = Color(0xFF8D6E63);

/// Vertical spacing between ruled lines, in logical pixels. The notebook body
/// uses the same line-height so text lands ON the lines.
const double kRuledLineSpacing = 32.0;

/// Horizontal offset of the warm-brown margin line from the left edge.
const double kMarginOffset = 32.0;

/// Paints evenly-spaced horizontal ruled lines (color [kRuledLine]) across the
/// whole canvas plus one vertical warm-brown margin line ([kMargin] at low
/// alpha) [kMarginOffset] from the left. Static — [shouldRepaint] is `false`.
class RuledPaperPainter extends CustomPainter {
  const RuledPaperPainter({
    this.spacing = kRuledLineSpacing,
    this.marginOffset = kMarginOffset,
  });

  /// Distance between consecutive ruled lines.
  final double spacing;

  /// Distance of the margin line from the left edge.
  final double marginOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = kRuledLine
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Horizontal ruled lines — start one spacing down so the first line sits
    // under the first row of text rather than at the very top edge.
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Vertical warm-brown margin line (low alpha so it reads as a soft accent).
    final marginPaint = Paint()
      ..color = kMargin.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(marginOffset, 0),
      Offset(marginOffset, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RuledPaperPainter oldDelegate) =>
      oldDelegate.spacing != spacing || oldDelegate.marginOffset != marginOffset;
}

/// Convenience wrapper that lays [child] onto a cream, gently-rounded, softly
/// shadowed page whose background is painted by [RuledPaperPainter] so body
/// text aligns on the ruled lines.
///
/// The child should use a left padding >= [kMarginOffset] so its text starts to
/// the right of the warm-brown margin line, and a line-height matching
/// [kRuledLineSpacing] so the handwriting sits on the rules.
class RuledPaper extends StatelessWidget {
  const RuledPaper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(44, 20, 20, 28),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kPaperCream,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: const RuledPaperPainter(),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
