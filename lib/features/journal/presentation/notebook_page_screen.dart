import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../garden/logic/garden_provider.dart';
import '../data/models/notebook.dart';
import '../logic/journal_provider.dart';
import 'widgets/entry_input_box.dart';
import 'widgets/notebook_cover.dart' show notebookColorOf;
import 'widgets/notebook_form_dialog.dart';
import 'widgets/ruled_paper_painter.dart';

/// Monotonic counter so two entries committed in the same microsecond still get
/// distinct ids (mirrors the local-id approach used elsewhere — no uuid pkg).
int _entryIdCounter = 0;

String _newEntryId() =>
    'e_${DateTime.now().microsecondsSinceEpoch}_${_entryIdCounter++}';

/// The notebook page editor — the CORE writing UX of Phase 11.
///
/// Renders the notebook's entries all-at-once on a cream, ruled, code-rendered
/// page ([RuledPaper]), grouped under printed/serif date headers, with same-day
/// entries separated by dotted lines and bodies in a handwriting font. Tapping a
/// blank region reveals an [EntryInputBox]; committing appends an entry via
/// [JournalProvider.addEntry] and awards garden XP through both garden hooks.
/// Entries are tap-to-edit / long-press-to-delete (whole-page replace). The
/// bottom toolbar (warm-brown [kMargin]) edits metadata, changes color, saves,
/// toggles visibility, and deletes the whole notebook (delete paths confirm).
class NotebookPageScreen extends StatefulWidget {
  const NotebookPageScreen({super.key, required this.notebook});

  final Notebook notebook;

  @override
  State<NotebookPageScreen> createState() => _NotebookPageScreenState();
}

class _NotebookPageScreenState extends State<NotebookPageScreen> {
  late Notebook _notebook;

  /// `null` = input hidden; non-null with empty editingId = new entry;
  /// non-null with an editingId = editing that entry.
  bool _writing = false;
  String? _editingEntryId;
  String? _editingInitialText;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _notebook = widget.notebook;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Reads the live copy from the provider by id where available, so external
  /// updates (e.g. a refresh) reflect here; falls back to local state.
  Notebook get _current {
    final provider = context.read<JournalProvider>();
    for (final n in provider.notebooks) {
      if (n.id == _notebook.id) return n;
    }
    return _notebook;
  }

  // ===========================================================================
  // Entry write / edit / delete
  // ===========================================================================

  void _startNewEntry() {
    setState(() {
      _writing = true;
      _editingEntryId = null;
      _editingInitialText = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _startEditEntry(NotebookEntry entry) {
    setState(() {
      _writing = true;
      _editingEntryId = entry.id;
      _editingInitialText = entry.content;
    });
  }

  void _cancelInput() {
    setState(() {
      _writing = false;
      _editingEntryId = null;
      _editingInitialText = null;
    });
  }

  Future<void> _submitInput(String text) async {
    final provider = context.read<JournalProvider>();
    final garden = context.read<GardenProvider>();
    final nb = _current;

    if (_editingEntryId != null) {
      // EDIT — rebuild that entry's content + replace whole page.
      final newEntries = [
        for (final e in nb.entries)
          if (e.id == _editingEntryId) e.copyWith(content: text) else e,
      ];
      final updated = nb.copyWith(
        entries: newEntries,
        updatedAt: DateTime.now(),
      );
      await provider.replacePage(updated);
      if (!mounted) return;
      setState(() {
        _notebook = updated;
        _writing = false;
        _editingEntryId = null;
        _editingInitialText = null;
      });
      _toast('Đã cập nhật');
    } else {
      // NEW — append entry, then award XP via BOTH garden hooks.
      final entry = NotebookEntry(
        id: _newEntryId(),
        content: text,
        date: DateTime.now(),
      );
      final updated = await provider.addEntry(nb, entry);
      if (!mounted) return;
      garden.onJournalEntryAdded();
      final wordCount = text
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      garden.onJournalEntryWithWordCount(wordCount);
      setState(() {
        _notebook = updated;
        _writing = false;
      });
      _toast('+XP cho khu vườn 🌱');
    }
  }

  Future<void> _deleteEntry(NotebookEntry entry) async {
    final confirmed = await _confirm(
      title: 'Xoá mục này?',
      message: 'Nội dung sẽ bị xoá vĩnh viễn.',
      confirmLabel: 'Xoá',
    );
    if (!confirmed || !mounted) return;
    final provider = context.read<JournalProvider>();
    final nb = _current;
    final newEntries = nb.entries.where((e) => e.id != entry.id).toList();
    final updated = nb.copyWith(
      entries: newEntries,
      updatedAt: DateTime.now(),
    );
    await provider.replacePage(updated);
    if (!mounted) return;
    setState(() => _notebook = updated);
    _toast('Đã xoá mục');
  }

  void _onEntryLongPress(NotebookEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kPaperCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: kMargin),
              title: Text('Sửa', style: GoogleFonts.nunito()),
              onTap: () {
                Navigator.of(ctx).pop();
                _startEditEntry(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFC0392B)),
              title: Text('Xoá', style: GoogleFonts.nunito()),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteEntry(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Toolbar actions
  // ===========================================================================

  void _editMetadata() {
    final overlay = Overlay.of(context);
    final provider = context.read<JournalProvider>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => NotebookFormDialog(
        initial: _current,
        onCancel: () => entry.remove(),
        onSubmit: (draft) async {
          entry.remove();
          await provider.update(draft);
          if (!mounted) return;
          setState(() => _notebook = draft);
          _toast('Đã lưu');
        },
      ),
    );
    overlay.insert(entry);
  }

  void _pickColor() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kPaperCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Màu bìa',
                style: GoogleFonts.quintessential(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3A2E20),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final token in kNotebookColors)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _changeColor(token);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: notebookColorOf(token),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: token == _current.color
                                ? const Color(0xFF3A2E20)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: token == _current.color
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeColor(String token) async {
    final provider = context.read<JournalProvider>();
    final updated = _current.copyWith(color: token, updatedAt: DateTime.now());
    await provider.update(updated);
    if (!mounted) return;
    setState(() => _notebook = updated);
    _toast('Đã đổi màu');
  }

  Future<void> _save() async {
    final provider = context.read<JournalProvider>();
    await provider.update(_current);
    if (!mounted) return;
    _toast('Đã lưu');
  }

  Future<void> _toggleVisibility() async {
    final provider = context.read<JournalProvider>();
    final nb = _current;
    final next = nb.visibility == NotebookVisibility.private_
        ? NotebookVisibility.public_
        : NotebookVisibility.private_;
    final updated = nb.copyWith(visibility: next, updatedAt: DateTime.now());
    await provider.update(updated);
    if (!mounted) return;
    setState(() => _notebook = updated);
    _toast(next == NotebookVisibility.public_ ? 'Công khai' : 'Riêng tư');
  }

  Future<void> _deleteNotebook() async {
    final confirmed = await _confirm(
      title: 'Xoá nhật ký này?',
      message: 'Cuốn "${_current.title}" và mọi mục sẽ bị xoá vĩnh viễn.',
      confirmLabel: 'Xoá',
    );
    if (!confirmed || !mounted) return;
    final provider = context.read<JournalProvider>();
    final navigator = Navigator.of(context);
    await provider.delete(_current.id);
    if (!mounted) return;
    navigator.pop();
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6B8E5A),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFCF6E8),
        title: Text(
          title,
          style: GoogleFonts.quintessential(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3A2E20),
          ),
        ),
        content: Text(
          message,
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
              confirmLabel,
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

  /// Groups entries by calendar day, ascending by day then by entry date.
  Map<DateTime, List<NotebookEntry>> _groupByDay(List<NotebookEntry> entries) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final map = <DateTime, List<NotebookEntry>>{};
    for (final e in sorted) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Rebuild on provider changes so external edits propagate; read the live nb.
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final live = provider.notebooks.firstWhere(
          (n) => n.id == _notebook.id,
          orElse: () => _notebook,
        );
        _notebook = live;
        final accent = notebookColorOf(live.color);
        final isPublic = live.visibility == NotebookVisibility.public_;

        return Scaffold(
          backgroundColor: const Color(0xFFEFE6D2),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    Expanded(child: _buildPage(live, accent)),
                    _buildToolbar(isPublic),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(Notebook nb, Color accent) {
    final grouped = _groupByDay(nb.entries);
    final dayKeys = grouped.keys.toList();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Tapping a blank area of the page begins a new entry.
        onTap: _writing ? null : _startNewEntry,
        child: RuledPaper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(nb, accent),
              const SizedBox(height: 12),
              if (nb.entries.isEmpty && !_writing)
                _buildEmptyHint()
              else
                for (final day in dayKeys) ...[
                  _buildDateHeader(day),
                  for (int i = 0; i < grouped[day]!.length; i++) ...[
                    _buildEntry(grouped[day]![i]),
                    if (i < grouped[day]!.length - 1) _buildDottedSeparator(),
                  ],
                  const SizedBox(height: 16),
                ],
              if (_writing)
                EntryInputBox(
                  key: ValueKey(_editingEntryId ?? 'new'),
                  initialText: _editingInitialText,
                  onSubmit: _submitInput,
                  onCancel: _cancelInput,
                )
              else
                _buildTapToWrite(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Notebook nb, Color accent) {
    return Row(
      children: [
        Text(
          nb.emoji.isEmpty ? '📓' : nb.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            nb.title.isEmpty ? 'Không tên' : nb.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.quintessential(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime day) {
    final label = DateFormat('EEEE, d MMMM yyyy').format(day);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.quintessential(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8D6E63),
        ),
      ),
    );
  }

  Widget _buildEntry(NotebookEntry entry) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _writing ? null : () => _startEditEntry(entry),
      onLongPress: () => _onEntryLongPress(entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          entry.content,
          style: GoogleFonts.caveat(
            fontSize: 22,
            height: 1.35,
            color: const Color(0xFF2E2616),
          ),
        ),
      ),
    );
  }

  Widget _buildDottedSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DottedLinePainter(),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'Chạm vào trang để bắt đầu viết',
          style: GoogleFonts.caveat(
            fontSize: 24,
            color: const Color(0xFF9A8B73),
          ),
        ),
      ),
    );
  }

  Widget _buildTapToWrite() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startNewEntry,
        child: Row(
          children: [
            Icon(Icons.add, size: 20, color: kMargin.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              'Viết tiếp...',
              style: GoogleFonts.caveat(
                fontSize: 20,
                color: kMargin.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(bool isPublic) {
    return Container(
      color: kMargin,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
          ),
          IconButton(
            tooltip: 'Sửa thông tin',
            onPressed: _editMetadata,
            icon: const Icon(Icons.edit),
            color: Colors.white,
          ),
          IconButton(
            tooltip: 'Đổi màu',
            onPressed: _pickColor,
            icon: const Icon(Icons.palette),
            color: Colors.white,
          ),
          IconButton(
            tooltip: 'Lưu',
            onPressed: _save,
            icon: const Icon(Icons.save),
            color: Colors.white,
          ),
          IconButton(
            tooltip: isPublic ? 'Công khai' : 'Riêng tư',
            onPressed: _toggleVisibility,
            icon: Icon(isPublic ? Icons.visibility : Icons.visibility_off),
            color: Colors.white,
          ),
          IconButton(
            tooltip: 'Xoá nhật ký',
            onPressed: _deleteNotebook,
            icon: const Icon(Icons.delete_outline),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// Thin dashed horizontal divider used between consecutive same-day entries.
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDBFA6)
      ..strokeWidth = 1.0;
    const dashWidth = 4.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
