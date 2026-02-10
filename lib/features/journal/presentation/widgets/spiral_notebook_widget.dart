import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/journal_model.dart';

class SpiralNotebookWidget extends StatelessWidget {
  final Journal journal;
  final Color notebookColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SpiralNotebookWidget({
    super.key,
    required this.journal,
    required this.notebookColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final notebookHeight = screenHeight * 0.28; // Approximately 1/3 of screen
    final notebookWidth = MediaQuery.of(context).size.width * 0.75;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: notebookWidth,
        height: notebookHeight,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Stack(
          children: [
            // Main notebook body with shadow
            Positioned(
              left: 20,
              top: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: notebookColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Interior ruled lines
                      _buildRuledLines(notebookHeight),
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 20, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Emoji at top
                            Text(
                              journal.emoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(height: 12),
                            // Journal name
                            Text(
                              journal.title,
                              style: GoogleFonts.caveat(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5D4E4E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            // Metadata
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(journal.createdAt),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.edit_note,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${journal.entries.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Spiral binding rings
            _buildSpiralBinding(notebookHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildRuledLines(double height) {
    final lineCount = (height / 24).floor();
    return Column(
      children: List.generate(
        lineCount,
        (index) => Container(
          height: 24,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpiralBinding(double height) {
    const ringCount = 4;

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            ringCount,
            (index) => Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[400],
                border: Border.all(color: Colors.grey[600]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              // Inner circle for 3D effect
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
