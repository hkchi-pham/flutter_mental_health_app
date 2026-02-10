import 'package:flutter/material.dart';

class NotebookPage extends StatelessWidget {
  final Widget child;
  final Widget? header;

  const NotebookPage({super.key, required this.child, this.header});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: const Color(0xFFE8EAF6),
            offset: const Offset(-4, 0),
            blurRadius: 0,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Lined paper background
          Positioned.fill(child: CustomPaint(painter: LinedPaperPainter())),

          // Spiral binding (Left side)
          Positioned(
            top: 20,
            bottom: 20,
            left: -14,
            width: 28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                12, // Number of rings
                (index) => _buildSpiralRing(),
              ),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) header!,
              Expanded(child: child),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpiralRing() {
    return Container(
      width: 24,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFD0D0D0),
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[100]!, Colors.grey[400]!],
          stops: [0.1, 0.4, 0.9],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
    );
  }
}

class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0F7FA)
          .withOpacity(0.5) // Very light blue lines
      ..strokeWidth = 1.5;

    final double lineHeight = 40.0;
    final double topMargin = 60.0;

    for (double y = topMargin; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical margin line
    final marginPaint = Paint()
      ..color = const Color(0xFFFFEBEE)
          .withOpacity(0.8) // Light red vertical line
      ..strokeWidth = 1.5;

    canvas.drawLine(
      const Offset(40, 0),
      const Offset(40,10),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
