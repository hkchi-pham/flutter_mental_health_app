import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../logic/journal_provider.dart';
import '../data/journal_model.dart';

class NotebookDetailScreen extends StatefulWidget {
  final String journalId;

  const NotebookDetailScreen({super.key, required this.journalId});

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  final TextEditingController _entryController = TextEditingController();
  bool _isWriting = false;

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_entryController.text.trim().isNotEmpty) {
      final success = await context.read<JournalProvider>().addEntry(
        widget.journalId,
        _entryController.text.trim(),
      );

      if (success) {
        _entryController.clear();
        if (mounted) {
          setState(() => _isWriting = false);
        }
      } else {
        if (mounted) {
          final error = context.read<JournalProvider>().error;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error ?? 'Có lỗi xảy ra')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, child) {
        final journal = provider.getJournalById(widget.journalId);
        if (journal == null) {
          return const Scaffold(
            body: Center(child: Text('Không tìm thấy nhật ký')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFF8E7),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFF8E7),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4E4E)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Text(journal.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  journal.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D4E4E),
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              // Notebook lines background
              CustomPaint(painter: NotebookLinesPainter(), child: Container()),
              // Content
              Column(
                children: [
                  Expanded(
                    child: journal.entries.isEmpty && !_isWriting
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  size: 64,
                                  color: Colors.brown[200],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Trang giấy trống...',
                                  style: GoogleFonts.caveat(
                                    fontSize: 24,
                                    color: Colors.brown[300],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhấn + để bắt đầu viết',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.brown[200],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            itemCount:
                                journal.entries.length + (_isWriting ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isWriting && index == 0) {
                                return _buildWritingArea();
                              }
                              final entryIndex = _isWriting ? index - 1 : index;
                              return _buildEntryItem(
                                journal.entries[entryIndex],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: _isWriting
              ? null
              : FloatingActionButton(
                  onPressed: () => setState(() => _isWriting = true),
                  backgroundColor: const Color(0xFFD4A574),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
        );
      },
    );
  }

  Widget _buildWritingArea() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D5B7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _entryController,
            maxLines: 5,
            autofocus: true,
            style: GoogleFonts.caveat(
              fontSize: 20,
              color: const Color(0xFF5D4E4E),
              height: 1.8,
            ),
            decoration: InputDecoration(
              hintText: 'Viết gì đó...',
              hintStyle: GoogleFonts.caveat(
                fontSize: 20,
                color: Colors.brown[200],
              ),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _entryController.clear();
                  setState(() => _isWriting = false);
                },
                child: Text(
                  'Hủy',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D8B8B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Lưu',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryItem(JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.content,
            style: GoogleFonts.caveat(
              fontSize: 22,
              color: const Color(0xFF5D4E4E),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.brown[100], thickness: 0.5),
        ],
      ),
    );
  }
}

class NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8D5B7).withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw horizontal lines
    const lineHeight = 32.0;
    for (double y = 60; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(30, y), Offset(size.width - 30, y), paint);
    }

    // Draw margin line
    final marginPaint = Paint()
      ..color = const Color(0xFFE8A5A5).withOpacity(0.5)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(35, 0), Offset(35, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
