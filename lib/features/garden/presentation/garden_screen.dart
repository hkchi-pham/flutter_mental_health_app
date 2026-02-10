import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/garden_provider.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waterAnimController;
  late Animation<double> _waterAnimation;

  @override
  void initState() {
    super.initState();
    _waterAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waterAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _waterAnimController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GardenProvider>().loadGardenState();
    });
  }

  @override
  void dispose() {
    _waterAnimController.dispose();
    super.dispose();
  }

  Future<void> _waterTree() async {
    final provider = context.read<GardenProvider>();
    if (provider.state.points >= 100) {
      _waterAnimController.forward(from: 0);
      final success = await provider.waterTree();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cây đã được tưới! 🌳',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF3F4D34),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cần 100 điểm để tưới cây!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GardenProvider>(
        builder: (context, provider, child) {
          final state = provider.state;

          return Stack(
            children: [
              // Sky with Layered Cloud Bands
              Positioned.fill(child: CustomPaint(painter: SkyPainter())),
              // Sun (Keeping original but adjusting position if needed, looks fine)
              Positioned(
                top: 60,
                right: 30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEECB75),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEECB75).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              // Mountains
              Positioned(
                bottom: 150, // Adjust based on painter
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 300),
                  painter: MountainsPainter(),
                ),
              ),
              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200, // Fixed height for ground
                child: Container(
                  color: const Color(0xFFC2CB96), // Green grass color
                ),
              ),
              // River and Landscape
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: CustomPaint(painter: RiverPainter()),
              ),
              // Tree or Empty Place
              Positioned(
                bottom: 100, // Adjusted relative to pond
                left: 0,
                right: 0,
                child: Center(
                  child: state.isSeedPlanted
                      ? AnimatedBuilder(
                          animation: _waterAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1 + (_waterAnimation.value * 0.05),
                              child: child,
                            );
                          },
                          child: _buildTree(state.treeLevel),
                        )
                      : const SizedBox.shrink(), // Nothing if not planted
                ),
              ),
              // Water drops animation
              if (provider.isWatering)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waterAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WaterDropsPainter(_waterAnimation.value),
                      );
                    },
                  ),
                ),
              // Header with points
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Custom XP Bar
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Stack(
                            children: [
                              // Progress Fill
                              FractionallySizedBox(
                                widthFactor: (state.points / state.maxPoints)
                                    .clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEECB75,
                                    ), // New Yellow/Gold
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 0,
                                    ),
                                  ),
                                ),
                              ),
                              // Text
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'XP ',
                                      style: GoogleFonts.permanentMarker(
                                        // Sketchy font if available, or just bold
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF3F4D34),
                                      ),
                                    ),
                                    Text(
                                      '${state.points} / ${state.maxPoints}',
                                      style: GoogleFonts.permanentMarker(
                                        fontSize: 14,
                                        color: const Color(0xFF3F4D34),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: IconButton(
                          onPressed: () => _showInfoDialog(),
                          icon: const Icon(Icons.menu, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Level indicator (Hidden if not planted)
              if (state.isSeedPlanted)
                Positioned(
                  top: 100,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Level ${state.treeLevel}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF494132),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTreeEmoji(state.treeLevel),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              // Action Button (Plant or Water)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: state.isSeedPlanted
                        ? (provider.isWatering ? null : _waterTree)
                        : () => context.read<GardenProvider>().plantSeed(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: !state.isSeedPlanted
                              ? [
                                  const Color(0xFFDDAF97),
                                  const Color(0xFF725C3F),
                                ] // Brown for planting
                              : state.points >= 100
                              ? [
                                  const Color(0xFFB3CAE2),
                                  const Color(0xFF3F4D34),
                                ] // Blue-Green for watering
                              : [Colors.grey[400]!, Colors.grey[500]!],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (!state.isSeedPlanted
                                        ? Colors.brown
                                        : Colors.blue)
                                    .withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            !state.isSeedPlanted ? '🌰' : '💧',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            !state.isSeedPlanted
                                ? 'Gieo hạt giống'
                                : provider.isWatering
                                ? 'Đang tưới...'
                                : 'Tưới cây (-100 XP)',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTree(int level) {
    // If level 0 (seedling), draw specific seedling art
    if (level == 0) {
      return Container(
        height: 60,
        width: 60,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: CustomPaint(painter: SeedlingPainter()),
      );
    }

    final treeSize = 120.0 + (level * 30);
    // Tree uses CustomPaint for organic shape
    return CustomPaint(
      size: Size(treeSize, treeSize * 1.2),
      painter: FlatTreePainter(level: level),
    );
  }

  String _getTreeEmoji(int level) {
    switch (level) {
      case 0:
        return '🌱';
      case 1:
        return '🌿';
      case 2:
        return '🪴';
      case 3:
        return '🌲';
      case 4:
        return '🌳';
      case 5:
        return '🌳✨';
      default:
        return '🌱';
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9F3F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🌳 Vườn của bạn',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3F4D34),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('📝 Viết nhật ký', '+20 điểm'),
            _buildInfoRow('💬 Trò chuyện', '+10 điểm'),
            _buildInfoRow('💧 Tưới cây', '-100 điểm'),
            const SizedBox(height: 16),
            Text(
              'Tưới cây để giúp cây lớn lên! Cây tượng trưng cho sự phát triển tâm hồn của bạn.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: GoogleFonts.poppins(color: const Color(0xFF3F4D34)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String activity, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(activity, style: GoogleFonts.poppins(fontSize: 14)),
          Text(
            points,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: points.startsWith('+')
                  ? const Color(0xFF3F4D34)
                  : const Color(0xFFDDAF97),
            ),
          ),
        ],
      ),
    );
  }
}

class SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fill background first
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF689FBF),
    );

    final colors = [
      const Color(0xFF689FBF),
      const Color(0xFF8FADC2),
      const Color(0xFFBFBAC2),
      const Color(0xFFD8C3B4),
      const Color(0xFFD1A791),
    ];

    // Draw bands from top to bottom
    // We already have top color. Let's draw the lower 4 bands.
    _drawCloudlyBand(canvas, size, colors[1], 0.2);
    _drawCloudlyBand(canvas, size, colors[2], 0.4);
    _drawCloudlyBand(canvas, size, colors[3], 0.6);
    _drawCloudlyBand(canvas, size, colors[4], 0.8);
  }

  void _drawCloudlyBand(
    Canvas canvas,
    Size size,
    Color color,
    double startYPercent,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final y = size.height * startYPercent;

    path.moveTo(0, y);
    // Irregular top edge
    path.cubicTo(
      size.width * 0.2,
      y - 15,
      size.width * 0.5,
      y + 15,
      size.width * 0.8,
      y - 5,
    );
    path.cubicTo(size.width * 0.9, y - 5, size.width, y, size.width, y);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MountainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Far Range (#56612E)
    _drawMountainLayer(
      canvas,
      size,
      const Color(0xFF56612E),
      heightFactor: 0.5,
      complexity: 3,
    );

    // 2. Mid Range (#7E694F)
    _drawMountainLayer(
      canvas,
      size,
      const Color(0xFF7E694F),
      heightFactor: 0.65,
      complexity: 4,
    );

    // 3. Near Range (#2C2922)
    _drawMountainLayer(
      canvas,
      size,
      const Color(0xFF2C2922),
      heightFactor: 0.8,
      complexity: 2,
    );
  }

  void _drawMountainLayer(
    Canvas canvas,
    Size size,
    Color color, {
    required double heightFactor,
    required int complexity,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();

    final startY = size.height * heightFactor;
    path.moveTo(0, size.height);
    path.lineTo(0, startY);

    // Create varied peaks
    double currentX = 0;
    double segmentWidth = size.width / complexity;

    for (int i = 0; i < complexity; i++) {
      final nextX = (i + 1) * segmentWidth;
      final peakHeight = 40.0 + (i % 2) * 30.0;

      path.cubicTo(
        currentX + segmentWidth * 0.25,
        startY - peakHeight, // Control 1
        currentX + segmentWidth * 0.75,
        startY + 10, // Control 2
        nextX,
        startY, // End
      );
      currentX = nextX;
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RiverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ground shadows first
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(-50, size.height - 100, 300, 150),
      shadowPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.6, size.height - 80, 200, 120),
      shadowPaint,
    );

    // ---- River ----
    // Main Water Body #AAC4BC
    final waterPaint = Paint()
      ..color = const Color(0xFFAAC4BC)
      ..style = PaintingStyle.fill;
    final riverPath = Path();

    // River Outline - Narrow winding stream
    riverPath.moveTo(size.width * 0.45, 0); // Start at horizon (middle-ish)

    // Left Bank
    riverPath.cubicTo(
      size.width * 0.35,
      size.height * 0.2,
      size.width * 0.1,
      size.height * 0.5,
      size.width * 0.2,
      size.height, // End left at bottom
    );

    // Bottom line
    riverPath.lineTo(size.width * 0.6, size.height);

    // Right Bank (Asymmetrical)
    riverPath.cubicTo(
      size.width * 0.4,
      size.height * 0.6,
      size.width * 0.55,
      size.height * 0.2,
      size.width * 0.55,
      0, // End right at horizon
    );
    riverPath.close();
    canvas.drawPath(riverPath, waterPaint);

    // Inner Highlight Strip #BED2BA - Follows flow in middle
    final highlightPaint = Paint()
      ..color = const Color(0xFFBED2BA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final highlightPath = Path();
    highlightPath.moveTo(size.width * 0.5, 0);
    highlightPath.cubicTo(
      size.width * 0.4,
      size.height * 0.2,
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.4,
      size.height,
    );
    canvas.drawPath(highlightPath, highlightPaint);

    // Edge Shadow #8DAF9B - Near left bank
    final shadowEdgePaint = Paint()
      ..color = const Color(0xFF8DAF9B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(riverPath, shadowEdgePaint);

    // ---- Vegetation / Bushes ----
    final bushPaintLight = Paint()
      ..color = const Color(0xFF799851)
      ..style = PaintingStyle.fill;
    final bushPaintDark = Paint()
      ..color = const Color(0xFF47622A)
      ..style = PaintingStyle.fill;

    // Organic Blob helper
    void drawBush(double x, double y, double r, Paint p) {
      canvas.drawCircle(Offset(x, y), r, p);
      canvas.drawCircle(Offset(x + r * 0.6, y + r * 0.2), r * 0.7, p);
      canvas.drawCircle(Offset(x - r * 0.5, y + r * 0.3), r * 0.6, p);
    }

    // Left Bank Bushes
    drawBush(size.width * 0.15, size.height * 0.8, 25, bushPaintDark);
    drawBush(size.width * 0.10, size.height * 0.85, 20, bushPaintLight);
    drawBush(size.width * 0.28, size.height * 0.45, 15, bushPaintDark);

    // Right Bank Bushes
    drawBush(size.width * 0.85, size.height * 0.9, 30, bushPaintLight);
    drawBush(size.width * 0.55, size.height * 0.3, 12, bushPaintDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FlatTreePainter extends CustomPainter {
  final int level;
  FlatTreePainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    // Colors
    final trunkColor = const Color(0xFF494132);
    final leavesMain = const Color(0xFF6D8F06);
    final leavesShadow = const Color(0xFF325600);

    final centerX = size.width / 2;
    final bottomY = size.height;

    // Trunk
    final trunkPath = Path();
    final trunkWidth = 10.0 + (level * 4);
    final trunkHeight = size.height * 0.4;

    trunkPath.moveTo(centerX - trunkWidth / 2, bottomY);
    // Slight curve
    trunkPath.quadraticBezierTo(
      centerX - trunkWidth / 4,
      bottomY - trunkHeight / 2,
      centerX - trunkWidth / 2,
      bottomY - trunkHeight,
    );
    trunkPath.lineTo(centerX + trunkWidth / 2, bottomY - trunkHeight);
    trunkPath.quadraticBezierTo(
      centerX + trunkWidth / 4,
      bottomY - trunkHeight / 2,
      centerX + trunkWidth / 2,
      bottomY,
    );
    trunkPath.close();
    canvas.drawPath(
      trunkPath,
      Paint()
        ..color = trunkColor
        ..style = PaintingStyle.fill,
    );

    // Canopy (Organic blobs)

    final canopyCenterY = bottomY - trunkHeight;
    final canopyRadius = 30.0 + (level * 10);

    // Draw Shadow layer first (Behind/Bottom)
    final shadowPaint = Paint()
      ..color = leavesShadow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX - 10, canopyCenterY + 10),
      canopyRadius * 0.9,
      shadowPaint,
    );
    canvas.drawCircle(
      Offset(centerX + 15, canopyCenterY + 5),
      canopyRadius * 0.85,
      shadowPaint,
    );

    // Draw Main Leaf Layer
    final leafPaint = Paint()
      ..color = leavesMain
      ..style = PaintingStyle.fill;

    // Central lobe
    canvas.drawCircle(
      Offset(centerX, canopyCenterY - 10),
      canopyRadius,
      leafPaint,
    );
    // Side lobes for organic shape
    canvas.drawCircle(
      Offset(centerX - canopyRadius * 0.6, canopyCenterY + 5),
      canopyRadius * 0.7,
      leafPaint,
    );
    canvas.drawCircle(
      Offset(centerX + canopyRadius * 0.6, canopyCenterY),
      canopyRadius * 0.75,
      leafPaint,
    );
    canvas.drawCircle(
      Offset(centerX, canopyCenterY - canopyRadius * 0.6),
      canopyRadius * 0.8,
      leafPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SeedlingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw Dirt mound
    final dirtPaint = Paint()..color = const Color(0xFF494132);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height),
        width: 40,
        height: 15,
      ),
      dirtPaint,
    );

    final paint = Paint()
      ..color =
          const Color(0xFF6D8F06) // New Green
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = const Color(0xFF6D8F06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Stem
    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(size.width / 2, size.height * 0.6),
      stemPaint,
    );

    // Left Leaf
    final leftLeafPath = Path();
    leftLeafPath.moveTo(size.width / 2, size.height * 0.6);
    leftLeafPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.4,
      size.width * 0.1,
      size.height * 0.2,
    );
    leftLeafPath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.4,
      size.width / 2,
      size.height * 0.6,
    );
    canvas.drawPath(leftLeafPath, paint);

    // Right Leaf
    final rightLeafPath = Path();
    rightLeafPath.moveTo(size.width / 2, size.height * 0.6);
    rightLeafPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.4,
      size.width * 0.9,
      size.height * 0.2,
    );
    rightLeafPath.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.4,
      size.width / 2,
      size.height * 0.6,
    );
    canvas.drawPath(rightLeafPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaterDropsPainter extends CustomPainter {
  final double progress;

  WaterDropsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBED2BA).withOpacity((1 - progress) * 0.8)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;

    for (var i = 0; i < 5; i++) {
      final startY = size.height * 0.2;
      final endY = size.height * 0.6;
      final currentY = startY + (endY - startY) * progress;
      final offsetX = (i - 2) * 30.0;

      canvas.drawCircle(Offset(centerX + offsetX, currentY), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
