import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/journal_provider.dart';
import '../data/journal_model.dart';
import 'notebook_detail_screen.dart';
import 'widgets/spiral_notebook_widget.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  // Pastel color palette for notebooks
  static const List<Color> notebookColors = [
    Color(0xFFCBDCEB), // Light blue/gray
    Color(0xFFF7A5A5), // Light coral pink
    Color(0xFFFCD8CD), // Light peach
    Color(0xFFA7C1A8), // Light sage green
    Color(0xFFD4C5F9), // Light lavender
    Color(0xFFFFE5CC), // Light apricot
    Color(0xFFC9E4CA), // Light mint
    Color(0xFFF5E6D3), // Light cream/beige
    Color(0xFFE8D5F2), // Light lilac
  ];

  Color _getNotebookColor(int index) {
    return notebookColors[index % notebookColors.length];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().loadJournals();
    });
  }

  void _showCreateJournalDialog() {
    final nameController = TextEditingController();
    String selectedEmoji = '📔';
    final emojis = ['📔', '💭', '🌟', '❤️', '🎯', '🌈', '📝', '🌸'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFFAF8F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Tạo sổ nhật ký mới',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D8B8B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Tên nhật ký...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chọn biểu tượng:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedEmoji = emoji),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedEmoji == emoji
                            ? const Color(0xFF3D8B8B).withOpacity(0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedEmoji == emoji
                              ? const Color(0xFF3D8B8B)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final success = await context
                      .read<JournalProvider>()
                      .createJournal(nameController.text, selectedEmoji);
                  if (context.mounted) {
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      final error = context.read<JournalProvider>().error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Có lỗi xảy ra'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D8B8B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Tạo',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header with avatar and username
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF3D8B8B),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/turtle_mascot.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF3D8B8B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D8B8B),
                        ),
                      ),
                      Text(
                        'Sổ nhật ký của bạn',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Journal list
            Expanded(
              child: Consumer<JournalProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.journals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có nhật ký nào',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF5D4E4E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _showCreateJournalDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Viết ngay'),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          ...List.generate(provider.journals.length, (index) {
                            final journal = provider.journals[index];
                            return SpiralNotebookWidget(
                              journal: journal,
                              notebookColor: _getNotebookColor(index),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NotebookDetailScreen(
                                      journalId: journal.id,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () => _showDeleteDialog(journal),
                            );
                          }),
                          const SizedBox(height: 80), // Space for FAB
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateJournalDialog,
        backgroundColor: const Color(0xFF3D8B8B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(Journal journal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhật ký?'),
        content: Text('Bạn có chắc muốn xóa "${journal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              context.read<JournalProvider>().deleteJournal(journal.id);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
