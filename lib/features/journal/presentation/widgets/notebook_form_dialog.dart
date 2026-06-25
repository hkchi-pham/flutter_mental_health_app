import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/notebook.dart';
import 'emoji_picker_grid.dart';
import 'notebook_cover.dart';

/// Monotonic counter so two notebooks created in the same microsecond still get
/// distinct ids (mirrors the ChangeOp.create local-id approach — no uuid pkg).
int _idCounter = 0;

String _newNotebookId() =>
    'nb_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

/// A compact, framed create/edit modal that floats over the notebooks list.
///
/// Entrance mirrors the badge popup: 200 ms easeOut scale (0.9→1.0) + content fade
/// + backdrop alpha (0→0.5). The backdrop is a tap-absorber that does NOT
/// dismiss — only the explicit Cancel/close calls [onCancel].
///
/// When [initial] is `null` this is CREATE mode (defaults: empty title,
/// emoji `📓`, color `green`, visibility private). When [initial] is non-null
/// it is EDIT mode (fields prefilled; id + entries + createdAt preserved).
class NotebookFormDialog extends StatefulWidget {
  const NotebookFormDialog({
    super.key,
    this.initial,
    required this.onSubmit,
    required this.onCancel,
  });

  /// Existing notebook to edit, or `null` to create a new one.
  final Notebook? initial;

  /// Called with the built [Notebook] when the user submits a valid form.
  final ValueChanged<Notebook> onSubmit;

  /// Called when the user cancels / closes the dialog.
  final VoidCallback onCancel;

  @override
  State<NotebookFormDialog> createState() => _NotebookFormDialogState();
}

class _NotebookFormDialogState extends State<NotebookFormDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _backdrop;

  late final TextEditingController _titleCtl;
  late String _emoji;
  late String _color;
  late NotebookVisibility _visibility;

  bool _emojiOpen = false;
  bool _titleError = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _titleCtl = TextEditingController(text: init?.title ?? '');
    _emoji = init?.emoji.isNotEmpty == true ? init!.emoji : '📓';
    _color = init?.color ?? kDefaultNotebookColor;
    _visibility = init?.visibility ?? NotebookVisibility.private_;

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final curved = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(curved);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _backdrop = Tween<double>(begin: 0.0, end: 0.5).animate(curved);
    _entrance.forward();
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }

    final init = widget.initial;
    final Notebook draft;
    if (init != null) {
      draft = init.copyWith(
        title: title,
        emoji: _emoji,
        color: _color,
        visibility: _visibility,
        updatedAt: DateTime.now(),
      );
    } else {
      draft = Notebook(
        id: _newNotebookId(),
        userId: '',
        title: title,
        emoji: _emoji,
        color: _color,
        visibility: _visibility,
        entries: const [],
        createdAt: DateTime.now(),
      );
    }
    widget.onSubmit(draft);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        return Stack(
          children: [
            // 1. Backdrop — absorbs taps but does NOT dismiss.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // no-op: cancel-only via the buttons
                child: Container(
                  color: Colors.black.withValues(alpha: _backdrop.value),
                ),
              ),
            ),
            // 2. Centered, compact framed panel.
            Center(
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _fade.value,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _buildPanel(context),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel(BuildContext context) {
    final accent = notebookColorOf(_color);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFCF6E8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Sửa nhật ký' : 'Nhật ký mới',
                  style: GoogleFonts.quintessential(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3A2E20),
                  ),
                ),
                const SizedBox(height: 16),

                // Title field.
                _buildTitleField(accent),
                const SizedBox(height: 16),

                // Emoji chip + inline picker.
                _buildEmojiRow(accent),
                if (_emojiOpen) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: EmojiPickerGrid(
                      selected: _emoji,
                      onSelected: (e) => setState(() {
                        _emoji = e;
                        _emojiOpen = false;
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Color swatches.
                _buildColorRow(),
                const SizedBox(height: 16),

                // Visibility toggle.
                _buildVisibilityRow(accent),
                const SizedBox(height: 22),

                // Actions.
                _buildActions(accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField(Color accent) {
    return TextField(
      controller: _titleCtl,
      style: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3A2E20),
      ),
      onChanged: (_) {
        if (_titleError) setState(() => _titleError = false);
      },
      decoration: InputDecoration(
        labelText: 'Tiêu đề',
        labelStyle: GoogleFonts.nunito(color: const Color(0xFF6B5A45)),
        errorText: _titleError ? 'Hãy nhập tiêu đề' : null,
        filled: true,
        fillColor: const Color(0xFFFFFDF7),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }

  Widget _buildEmojiRow(Color accent) {
    return Row(
      children: [
        Text(
          'Biểu tượng',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B5A45),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => setState(() => _emojiOpen = !_emojiOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Icon(
                  _emojiOpen ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: const Color(0xFF6B5A45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Màu',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B5A45),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final token in kNotebookColors)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildSwatch(token),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwatch(String token) {
    final selected = token == _color;
    final color = notebookColorOf(token);
    return GestureDetector(
      onTap: () => setState(() => _color = token),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF3A2E20) : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildVisibilityRow(Color accent) {
    final isPublic = _visibility == NotebookVisibility.public_;
    return Row(
      children: [
        Icon(
          isPublic ? Icons.public : Icons.lock,
          size: 20,
          color: const Color(0xFF6B5A45),
        ),
        const SizedBox(width: 10),
        Text(
          isPublic ? 'Công khai' : 'Riêng tư',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B5A45),
          ),
        ),
        const Spacer(),
        Switch(
          value: isPublic,
          activeTrackColor: accent,
          onChanged: (v) => setState(() {
            _visibility =
                v ? NotebookVisibility.public_ : NotebookVisibility.private_;
          }),
        ),
      ],
    );
  }

  Widget _buildActions(Color accent) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: const Color(0xFF6B5A45),
            ),
            child: Text(
              'Huỷ',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isEdit ? 'Lưu' : 'Tạo',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
