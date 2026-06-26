import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ruled_paper_painter.dart';

/// An inline, expanding multi-line input rendered on the cream paper. Used for
/// BOTH writing a new entry and editing an existing one (pass [initialText] to
/// prefill).
///
/// The field grows with content (`maxLines: null`, autofocus). A trailing
/// checkmark [IconButton] (warm-brown [kMargin]) commits via [onSubmit] — only
/// when the trimmed text is non-empty — and a small `×` cancels via [onCancel].
/// Emoji typed into the field is preserved (no input formatters strip it).
class EntryInputBox extends StatefulWidget {
  const EntryInputBox({
    super.key,
    this.initialText,
    required this.onSubmit,
    required this.onCancel,
  });

  /// Prefilled text when editing; `null`/empty when writing a new entry.
  final String? initialText;

  /// Called with the trimmed text when the user taps the submit checkmark.
  /// Only invoked when the trimmed text is non-empty.
  final ValueChanged<String> onSubmit;

  /// Called when the user taps the cancel (×) button.
  final VoidCallback onCancel;

  @override
  State<EntryInputBox> createState() => _EntryInputBoxState();
}

class _EntryInputBoxState extends State<EntryInputBox> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kMargin.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.patrickHand(
                fontSize: 22,
                height: kRuledLineSpacing / 22,
                color: const Color(0xFF3A2E20),
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Viết điều gì đó...',
                hintStyle: GoogleFonts.patrickHand(
                  fontSize: 22,
                  color: const Color(0xFF9A8B73),
                ),
              ),
            ),
          ),
          // Cancel (×)
          IconButton(
            tooltip: 'Huỷ',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, size: 22),
            color: const Color(0xFF9A8B73),
          ),
          // Submit (checkmark) — disabled (dimmed) while empty.
          IconButton(
            tooltip: 'Lưu',
            visualDensity: VisualDensity.compact,
            onPressed: _hasText ? _submit : null,
            icon: const Icon(Icons.check, size: 24),
            color: kMargin,
            disabledColor: kMargin.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
