import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/models/notebook.dart';

/// Maps a notebook color token (one of [kNotebookColors]) to its accent
/// [Color]. Used both as the cover-image errorBuilder fallback tint and as the
/// dialog accent in the create/edit form. Unknown tokens fall back to green.
Color notebookColorOf(String token) {
  switch (token) {
    case 'brown':
      return const Color(0xFF8D6E63);
    case 'blue':
      return const Color(0xFF6A8CAF);
    case 'pink':
      return const Color(0xFFD88BA0);
    case 'yellow':
      return const Color(0xFFD8B86A);
    case 'green':
    default:
      return const Color(0xFF6B8E5A);
  }
}

/// A single notebook "cover" card for the journal list.
///
/// Renders the color-specific cover image
/// (`assets/ui_icons/frames/card_{color}_journal_@3x.png`) with
/// `BoxFit.contain` (per the per-type rules for card/frame assets) and an
/// errorBuilder fallback to a rounded container tinted by [notebookColorOf].
///
/// Overlaid on the cover:
///   • emoji (top-left, large),
///   • title (google_fonts, bold, ellipsis),
///   • last-written date (intl `d MMM yyyy`),
///   • a visibility icon bottom-right (lock = private, globe = public).
class NotebookCover extends StatelessWidget {
  const NotebookCover({
    super.key,
    required this.notebook,
    required this.onTap,
  });

  final Notebook notebook;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = notebookColorOf(notebook.color);
    final dateLabel = DateFormat('d MMM yyyy').format(notebook.createdAt);
    final isPrivate = notebook.visibility == NotebookVisibility.private_;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        // Wide cover card — a notebook lying landscape on the shelf.
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Cover image (color-specific) with tinted fallback.
            Image.asset(
              'assets/ui_icons/frames/card_${notebook.color}_journal_@3x.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Overlay content.
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
              child: Stack(
                children: [
                  // Title (+ emoji to its right) and date — centered block.
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                notebook.title.isEmpty
                                    ? 'Không tên'
                                    : notebook.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                // Bigger, softer handwriting-style title.
                                style: GoogleFonts.dancingScript(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3A2E20),
                                ),
                              ),
                            ),
                            // Emoji to the RIGHT of the title (omitted for 'none').
                            if (notebook.emoji.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                notebook.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateLabel,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B5A45),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Visibility icon — bottom-right.
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      isPrivate ? Icons.lock : Icons.public,
                      size: 20,
                      color: const Color(0xFF6B5A45),
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
}
