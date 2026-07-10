import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../logic/profile_provider.dart';
import '../../../auth/data/auth_session.dart';

/// Framed name-edit modal following the [SettingsMenuPopup] / badge-popup
/// visual pattern.
///
/// Entrance: 200ms easeOut scale (0.9→1.0) + fade (0→1) + backdrop (0→0.5).
/// Frame: [frame_info_page_@2x.png] with cream interior fill [Color(0xFFEBDDB8)].
/// Cancel button: [info_page_cancel_btn_@2x.png] in the right gutter.
/// Title: "Chỉnh sửa tên" via [GoogleFonts.quintessential].
///
/// Behaviour:
///   - Save ("Lưu"): trims input; disabled when empty; while saving shows a
///     spinner on the button; on success (provider returns true) calls [onClose];
///     on failure stays open + shows inline error "Không lưu được. Thử lại."
///   - Cancel ("Huỷ") and the gutter X button: both call [onClose].
///
/// The host inserts this widget as an [OverlayEntry] or [Stack] overlay and
/// provides [onClose] to remove it.
class EditNameDialog extends StatefulWidget {
  const EditNameDialog({
    super.key,
    required this.initialName,
    required this.onClose,
  });

  /// The current fullname pre-filling the text field.
  final String initialName;

  /// Called when the dialog should be removed (save success OR cancel).
  final VoidCallback onClose;

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _backdrop;

  late final TextEditingController _nameCtrl;

  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
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
    _nameCtrl.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final trimmed = _nameCtrl.text.trim();
    if (trimmed.isEmpty || _saving) return;

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final userId = context.read<AuthSession>().userId ?? '';
    final ok = await context.read<ProfileProvider>().editName(
          trimmed,
          userId: userId,
        );

    if (!mounted) return;

    if (ok) {
      widget.onClose();
    } else {
      setState(() {
        _saving = false;
        _errorText = 'Không lưu được. Thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        return Stack(
          children: [
            // 1. Dark backdrop — taps absorbed, cancel-only (mirrors badge/settings popup)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // intentional no-op — only X / Huỷ dismisses
                child: Container(
                  color: Colors.black.withValues(alpha: _backdrop.value),
                ),
              ),
            ),
            // 2. Centered framed popup
            Center(
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _fade.value,
                  child: _buildFrame(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFrame(BuildContext context) {
    final mq = MediaQuery.of(context);
    final popupWidth = (mq.size.width * 0.80).clamp(260.0, 400.0);
    final popupHeight = (mq.size.height * 0.38).clamp(240.0, 360.0);

    // Cream fill bezel fractions — matching Phase 6/7/8 frame_info_page measurements.
    const double creamLeftFrac = 0.0938;
    const double creamRightFrac = 0.0928;
    const double creamTopFrac = 0.0775;
    const double creamBottomFrac = 0.07;

    const double padLeftFrac = 0.11;
    const double padRightFrac = 0.11;
    const double padTopFrac = 0.10;
    const double padBottomFrac = 0.10;

    // Gutter for the cancel button — sits to the right of the frame.
    const double cancelGutter = 56.0;

    return SizedBox(
      width: popupWidth + cancelGutter * 2,
      height: popupHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The actual popup frame — centered inside the wider hit-region box.
          Positioned(
            left: cancelGutter,
            top: 0,
            width: popupWidth,
            height: popupHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cream interior fill
                Positioned(
                  top: popupHeight * creamTopFrac,
                  bottom: popupHeight * creamBottomFrac,
                  left: popupWidth * creamLeftFrac,
                  right: popupWidth * creamRightFrac,
                  child: Container(color: const Color(0xFFEBDDB8)),
                ),
                // Frame background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/ui_icons/frames/frame_info_page_@2x.png',
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBDDB8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8B6F47),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                // Interior content
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      popupWidth * padLeftFrac,
                      popupHeight * padTopFrac,
                      popupWidth * padRightFrac,
                      popupHeight * padBottomFrac,
                    ),
                    child: _buildInterior(context),
                  ),
                ),
              ],
            ),
          ),
          // Cancel button (X) in the right gutter
          Positioned(
            top: popupHeight * 0.05,
            right: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _saving ? null : widget.onClose,
              child: Image.asset(
                'assets/ui_icons/icons/info_page_cancel_btn_@2x.png',
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.cancel,
                  size: 32,
                  color: Color(0xFF2F3E2E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterior(BuildContext context) {
    final trimmed = _nameCtrl.text.trim();
    final saveEnabled = trimmed.isNotEmpty && !_saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          'Chỉnh sửa tên',
          textAlign: TextAlign.center,
          style: GoogleFonts.quintessential(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3E2E),
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          color: const Color(0xFF8B6F47).withValues(alpha: 0.4),
          thickness: 1,
        ),
        const SizedBox(height: 10),

        // Name text field
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameCtrl,
          builder: (context, value, _) {
            return TextField(
              controller: _nameCtrl,
              enabled: !_saving,
              textAlign: TextAlign.center,
              style: GoogleFonts.quintessential(
                fontSize: 16,
                color: const Color(0xFF2F3E2E),
              ),
              decoration: InputDecoration(
                hintText: 'Tên hiển thị',
                hintStyle: GoogleFonts.quintessential(
                  color: const Color(0xFF8B6F47).withValues(alpha: 0.5),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(0xFF8B6F47).withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2F3E2E), width: 1.5),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(0xFF8B6F47).withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          },
        ),

        // Inline error message
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 12,
              color: Colors.red.shade700,
            ),
          ),
        ],

        const Spacer(),

        // Action buttons: Lưu + Huỷ
        Row(
          children: [
            // Huỷ button
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : widget.onClose,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5ECD8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8B6F47).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Huỷ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quintessential(
                      fontSize: 15,
                      color: const Color(0xFF2F3E2E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Lưu button
            Expanded(
              child: GestureDetector(
                onTap: saveEnabled ? _handleSave : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: saveEnabled
                        ? const Color(0xFF2F3E2E)
                        : const Color(0xFF2F3E2E).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _saving
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Lưu',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quintessential(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
