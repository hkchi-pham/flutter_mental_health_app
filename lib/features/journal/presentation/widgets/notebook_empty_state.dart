import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotebookEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const NotebookEmptyState({super.key, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 400, // Fixed height for the "page"
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            // Inner paper border effect
            BoxShadow(
              color: const Color(0xFFE8EAF6), // Light indigo tint
              offset: const Offset(8, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Spiral rings at the top
            Positioned(
              top: -12,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(8, (index) => _buildSpiralRing()),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cute pencil/book icon similar to reference
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D6), // Soft yellow/orange
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      size: 48,
                      color: Color(0xFFD4A574),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Text lines effect
                  Container(
                    width: double.infinity,
                    height: 2,
                    color: const Color(0xFFF0F0F0),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chưa có nhật ký nào',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5D4E4E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy bắt đầu viết câu chuyện của bạn ngay hôm nay!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onCreatePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D8B8B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        'Tạo nhật ký mới',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiralRing() {
    return Container(
      width: 14,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
          stops: const [0.1, 0.5, 0.9],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
