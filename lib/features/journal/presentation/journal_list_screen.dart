import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../data/models/notebook.dart';
import '../logic/journal_provider.dart';
import 'widgets/notebook_cover.dart';
import 'widgets/notebook_form_dialog.dart';

/// The Journal tab — a full-screen list of notebook covers.
///
/// Layout:
///   • Full-bleed `journal_screen_background.png` (cream fallback).
///   • Header: painterly "Nhật Ký" title + `btn_new_journal` button that opens
///     the [NotebookFormDialog] via an [OverlayEntry].
///   • Body (wrapped in [MaxWidthBox]): a [Consumer] of [JournalProvider] —
///     loading spinner / friendly empty state / a [RefreshIndicator] +
///     [ListView] of [NotebookCover]s with infinite scroll.
///   • Each cover swipes left (endToStart) to delete after a confirm dialog.
///
/// Coordination: [JournalProvider] is wired by Plan 11-03. Tapping a cover
/// pushes a placeholder editor [Scaffold] — Plan 11-05 replaces it with the
/// real notebook page editor.
class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _dialogEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JournalProvider>().loadInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _removeDialog();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final provider = context.read<JournalProvider>();
    if (_scrollController.position.extentAfter < 300 &&
        provider.hasMore &&
        !provider.loadingMore) {
      provider.loadMore();
    }
  }

  // ---------------------------------------------------------------------------
  // Create dialog (OverlayEntry)
  // ---------------------------------------------------------------------------

  void _openCreateDialog() {
    _removeDialog();
    final provider = context.read<JournalProvider>();
    final overlay = Overlay.of(context);
    _dialogEntry = OverlayEntry(
      builder: (_) => NotebookFormDialog(
        onCancel: _removeDialog,
        onSubmit: (draft) async {
          _removeDialog();
          await provider.create(draft);
          if (!mounted) return;
          _showToast('Đã tạo nhật ký');
        },
      ),
    );
    overlay.insert(_dialogEntry!);
  }

  void _removeDialog() {
    _dialogEntry?.remove();
    _dialogEntry = null;
  }

  void _showToast(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6B8E5A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete confirm
  // ---------------------------------------------------------------------------

  Future<bool> _confirmDelete(Notebook nb) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFCF6E8),
        title: Text(
          'Xoá nhật ký này?',
          style: GoogleFonts.quintessential(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3A2E20),
          ),
        ),
        content: Text(
          'Cuốn "${nb.title}" sẽ bị xoá vĩnh viễn.',
          style: GoogleFonts.nunito(color: const Color(0xFF6B5A45)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Huỷ', style: GoogleFonts.nunito()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Xoá',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC0392B),
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ---------------------------------------------------------------------------
  // Open a notebook (placeholder editor — Plan 11-05 wires the real one)
  // ---------------------------------------------------------------------------

  void _openNotebook(Notebook nb) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PlaceholderNotebookScreen(notebook: nb),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed background.
          Image.asset(
            'assets/screens/journal_screen_background.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Container(color: const Color(0xFFF3E9D2)),
          ),

          // 2. Content.
          SafeArea(
            child: MaxWidthBox(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Nhật Ký',
              style: GoogleFonts.quintessential(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3A2E20),
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _openCreateDialog,
            behavior: HitTestBehavior.opaque,
            child: Image.asset(
              'assets/ui_icons/icons/btn_new_journal_@3x.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B8E5A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final notebooks = provider.notebooks;

        if (provider.loading && notebooks.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6B8E5A)),
          );
        }

        if (!provider.loading && notebooks.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          color: const Color(0xFF6B8E5A),
          onRefresh: provider.refresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: notebooks.length + (provider.loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= notebooks.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF6B8E5A),
                      ),
                    ),
                  ),
                );
              }

              final nb = notebooks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Dismissible(
                  key: ValueKey(nb.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(nb),
                  onDismissed: (_) => provider.delete(nb.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0392B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 30),
                  ),
                  child: NotebookCover(
                    notebook: nb,
                    onTap: () => _openNotebook(nb),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    // ListView so pull-to-refresh still works when empty.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Center(child: Text('📖', style: TextStyle(fontSize: 64))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Chưa có nhật ký nào — nhấn + để tạo cuốn đầu tiên',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B5A45),
            ),
          ),
        ),
      ],
    );
  }
}

/// Temporary stand-in for the notebook page editor.
///
/// Plan 11-05 replaces the push target in [_JournalListScreenState._openNotebook]
/// with the real `NotebookPageScreen(notebook: nb)`.
class _PlaceholderNotebookScreen extends StatelessWidget {
  const _PlaceholderNotebookScreen({required this.notebook});

  final Notebook notebook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          notebook.title,
          style: GoogleFonts.quintessential(),
        ),
        backgroundColor: notebookColorOf(notebook.color),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${notebook.emoji}\n\nTrang nhật ký sẽ có ở bản cập nhật sau.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: const Color(0xFF6B5A45),
            ),
          ),
        ),
      ),
    );
  }
}
