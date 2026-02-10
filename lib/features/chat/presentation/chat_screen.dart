import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/chat_provider.dart';
import '../data/message_model.dart';
import 'widgets/mood_log_box.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _controller.text;
    if (content.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(content);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Garden background
          _buildBackground(),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom app bar
                _buildAppBar(),
                // Messages
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      if (provider.messages.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🌸',
                                  style: TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chào bạn!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5D4E4E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hãy chia sẻ cảm xúc của bạn...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          80,
                        ), // Extra bottom padding for input
                        itemCount:
                            provider.messages.length + 1, // +1 for MoodLogBox
                        itemBuilder: (context, index) {
                          // Note: ListView is reverse: true
                          // index 0 is the latest message (bottom)
                          // index length-1 is the first item (top) - which should be MoodLogBox

                          if (index == provider.messages.length) {
                            return MoodLogBox(
                              onMoodSelected: (mood) {
                                // Optional: Handle mood selection log
                                print('Selected mood: $mood');
                              },
                            );
                          }

                          final message = provider.messages[index];
                          return _buildMessageItem(message);
                        },
                      );
                    },
                  ),
                ),
                // Loading indicator
                if (context.watch<ChatProvider>().isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF3D8B8B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Đang suy nghĩ...',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Error message
                if (context.watch<ChatProvider>().error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.watch<ChatProvider>().error!,
                      style: GoogleFonts.poppins(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                // Input area
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // 1. Pastel Sky (Top 50%)
        Positioned.fill(child: CustomPaint(painter: PastelSkyPainter())),

        // 2. Rolling Hills (Midground)
        Positioned.fill(child: CustomPaint(painter: RollingHillsPainter())),

        // 3. Meadow Foreground
        Positioned.fill(child: CustomPaint(painter: MeadowPainter())),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                const Text('🌷', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Vườn tâm sự',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D4E4E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    final isMe = message.isSentByMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F3E5), // Soft cream
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8D5B7), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🐢', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // Bot: Soft off-white
                // User: Pastel green / muted teal
                color: isMe
                    ? const Color(0xFFA8C8A6) // Pastel Green
                    : const Color(0xFFFFFDF5), // Off-white cream
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      // Dark Gray text for readability
                      color: const Color(0xFF4A4A4A),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF8D8D8D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDCECC9), // Light green
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text('😊', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 10,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F0),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFE8D5B7)),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Chia sẻ cảm xúc của bạn...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D8B8B), Color(0xFF5BA3A3)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3D8B8B).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PastelSkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft Gradient Sky
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFD4E6F1), // Pale Mint/Blueish
        const Color(0xFFF9E79F), // Warm Cream
        const Color(0xFFFAD7A0), // Peach
        const Color(0xFFF5B7B1), // Blush Pink
      ],
      stops: [0.0, 0.4, 0.7, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    // 2. Painterly Clouds (Soft, asymmetrical)
    _drawCloud(
      canvas,
      size.width * 0.1,
      size.height * 0.15,
      60,
      const Color(0xFFFFFFFF).withOpacity(0.6),
    );
    _drawCloud(
      canvas,
      size.width * 0.6,
      size.height * 0.1,
      80,
      const Color(0xFFFFFFFF).withOpacity(0.4),
    );
    _drawCloud(
      canvas,
      size.width * 0.85,
      size.height * 0.25,
      50,
      const Color(0xFFFFFFFF).withOpacity(0.5),
    );
  }

  void _drawCloud(Canvas canvas, double x, double y, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // Organic blobs
    canvas.drawCircle(Offset(x, y), size * 0.6, paint);
    canvas.drawCircle(
      Offset(x + size * 0.5, y + size * 0.2),
      size * 0.5,
      paint,
    );
    canvas.drawCircle(
      Offset(x - size * 0.4, y + size * 0.1),
      size * 0.4,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RollingHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Hills (Hazy, Lighter)
    _drawHills(
      canvas,
      size,
      const Color(0xFFA9DFBF).withOpacity(0.4), // Hazy Green
      0.45, // Start height Y
      3, // frequency
    );

    // 2. Midground Hills
    _drawHills(
      canvas,
      size,
      const Color(0xFFA3E4D7).withOpacity(0.6), // Tealish Green
      0.55,
      2,
    );

    // 3. Foreground Hills Outline (Base for meadow)
    // We can just imply them or let meadow painter handle the very front.
    // Let's add one more distinct hill layer
    _drawHills(
      canvas,
      size,
      const Color(0xFFAED6F1).withOpacity(0.3), // Distant Blueish
      0.35,
      4,
    );

    // 4. Winding Path
    // S-shape from bottom center to horizon
    final path = Path();
    path.moveTo(size.width * 0.5, size.height); // Bottom center
    path.cubicTo(
      size.width * 0.7,
      size.height * 0.85,
      size.width * 0.3,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.55, // Horizon
    );

    // Variable width path (thick precision handling is hard with stroke, so we rely on strokeWidth 10)
    // To make it look like it gets smaller, we might need a path outline or just stroke.
    // Let's use fill for perspective if possible, or just simple stroke for "illustration" style.
    // Illustration style often keeps constant width or simple tapering.

    // Let's try filling a tapered path for better perspective
    final pathFill = Path();
    pathFill.moveTo(size.width * 0.4, size.height);
    pathFill.lineTo(size.width * 0.6, size.height); // Wide at bottom

    // Curves to horizon
    pathFill.cubicTo(
      size.width * 0.75,
      size.height * 0.85,
      size.width * 0.35,
      size.height * 0.7,
      size.width * 0.52,
      size.height * 0.55,
    );
    pathFill.lineTo(size.width * 0.48, size.height * 0.55); // Narrow at top
    pathFill.cubicTo(
      size.width * 0.3,
      size.height * 0.7,
      size.width * 0.7,
      size.height * 0.85,
      size.width * 0.4,
      size.height,
    );

    canvas.drawPath(pathFill, Paint()..color = const Color(0xFFF6DDCC));
  }

  void _drawHills(
    Canvas canvas,
    Size size,
    Color color,
    double heightFactor,
    double freq,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();

    final startY = size.height * heightFactor;
    path.moveTo(0, size.height);
    path.lineTo(0, startY);

    final widthVar = size.width / freq;

    for (int i = 0; i < freq; i++) {
      final startX = i * widthVar;
      final endX = (i + 1) * widthVar;
      path.cubicTo(
        startX + widthVar * 0.25,
        startY - 30,
        startX + widthVar * 0.75,
        startY + 30,
        endX,
        startY,
      );
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MeadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Grassy Meadow (Bottom 40%)
    final meadowPaint = Paint()..color = const Color(0xFFABEBC6); // Fresh Green
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.6);
    // Slight curve for meadow horizon line
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.55,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, meadowPaint);

    // 2. Shadows / Texture
    final shadowPaint = Paint()
      ..color = const Color(0xFF82E0AA).withOpacity(0.5);
    // Draw some stylized grass texture or soft shadows
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      50,
      shadowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.85),
      60,
      shadowPaint,
    );

    // 3. Wildflowers
    final flowerColors = [
      const Color(0xFFF1948A), // Soft Red
      const Color(0xFFBB8FCE), // Purple
      const Color(0xFFF7DC6F), // Yellow
    ];

    // Clusters dense at bottom
    _drawFlowerCluster(
      canvas,
      size.width * 0.1,
      size.height * 0.9,
      5,
      flowerColors[0],
    );
    _drawFlowerCluster(
      canvas,
      size.width * 0.25,
      size.height * 0.95,
      7,
      flowerColors[1],
    );
    _drawFlowerCluster(
      canvas,
      size.width * 0.8,
      size.height * 0.92,
      6,
      flowerColors[2],
    );
    _drawFlowerCluster(
      canvas,
      size.width * 0.6,
      size.height * 0.85,
      4,
      flowerColors[0],
    );
  }

  void _drawFlowerCluster(
    Canvas canvas,
    double x,
    double y,
    int count,
    Color color,
  ) {
    final paint = Paint()..color = color;
    for (int i = 0; i < count; i++) {
      // Simple dot flowers
      canvas.drawCircle(Offset(x + (i * 15) % 30, y + (i * 5)), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
