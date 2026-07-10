import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../logic/profile_provider.dart';

/// Framed change-password dialog following the [EditNameDialog] / badge-popup
/// visual pattern.
///
/// Entrance: 200ms easeOut scale (0.9→1.0) + fade (0→1) + backdrop (0→0.5).
/// Frame: [frame_info_page_@2x.png] with cream interior fill [Color(0xFFEBDDB8)].
/// Cancel button: [info_page_cancel_btn_@2x.png] in the right gutter.
///
/// Three obscured fields: old password / new password / confirm new password.
/// Client-side validation runs before any network call:
///   - all three non-empty
///   - new >= 6 characters
///   - new == confirm
/// On valid submit: spinner → [ProfileProvider.changePassword] →
///   null (success) → success message then closes;
///   non-null (VN error) → inline error, dialog stays open.
class ChangePasswordDialog extends StatefulWidget {
  /// Called when the dialog should be removed (success OR cancel / X).
  final VoidCallback onClose;

  const ChangePasswordDialog({super.key, required this.onClose});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _backdrop;

  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorText;
  bool _succeeded = false;

  @override
  void initState() {
    super.initState();
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
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _entrance.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validate() {
    final old = _oldCtrl.text.trim();
    final newPw = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (old.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      return 'Vui lòng điền đầy đủ các trường.';
    }
    if (newPw.length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }
    if (newPw != confirm) {
      return 'Mật khẩu nhập lại không khớp.';
    }
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (_submitting) return;

    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final err = await context.read<ProfileProvider>().changePassword(
          oldPassword: _oldCtrl.text.trim(),
          newPassword: _newCtrl.text,
        );

    if (!mounted) return;

    if (err == null) {
      // Success — show confirmation then close
      setState(() {
        _submitting = false;
        _succeeded = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) widget.onClose();
    } else {
      setState(() {
        _submitting = false;
        _errorText = err; // VN error string from provider
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        return Stack(
          children: [
            // Dark backdrop — cancel-only (mirrors badge/settings popup pattern)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // intentional no-op — only X / Huỷ dismisses
                child: Container(
                  color: Colors.black.withValues(alpha: _backdrop.value),
                ),
              ),
            ),
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
    final popupWidth = (mq.size.width * 0.85).clamp(260.0, 420.0);
    final popupHeight = (mq.size.height * 0.56).clamp(320.0, 480.0);

    const double creamLeftFrac = 0.0938;
    const double creamRightFrac = 0.0928;
    const double creamTopFrac = 0.0775;
    const double creamBottomFrac = 0.07;

    const double padLeftFrac = 0.11;
    const double padRightFrac = 0.11;
    const double padTopFrac = 0.09;
    const double padBottomFrac = 0.09;

    const double cancelGutter = 56.0;

    return SizedBox(
      width: popupWidth + cancelGutter * 2,
      height: popupHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
                // Frame image
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
                    child: _buildInterior(),
                  ),
                ),
              ],
            ),
          ),
          // Cancel (X) button in the right gutter
          Positioned(
            top: popupHeight * 0.05,
            right: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _submitting ? null : widget.onClose,
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

  Widget _buildInterior() {
    if (_succeeded) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF2F7A3A), size: 40),
          const SizedBox(height: 12),
          Text(
            'Đổi mật khẩu thành công!',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2F7A3A),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          'Đổi mật khẩu',
          textAlign: TextAlign.center,
          style: GoogleFonts.quintessential(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3E2E),
          ),
        ),
        const SizedBox(height: 6),
        Divider(
          color: const Color(0xFF8B6F47).withValues(alpha: 0.4),
          thickness: 1,
        ),
        const SizedBox(height: 10),

        // Old password
        _PasswordField(
          controller: _oldCtrl,
          hint: 'Mật khẩu cũ',
          enabled: !_submitting,
        ),
        const SizedBox(height: 8),

        // New password
        _PasswordField(
          controller: _newCtrl,
          hint: 'Mật khẩu mới',
          enabled: !_submitting,
        ),
        const SizedBox(height: 8),

        // Confirm new password
        _PasswordField(
          controller: _confirmCtrl,
          hint: 'Nhập lại mật khẩu mới',
          enabled: !_submitting,
        ),

        // Inline error
        if (_errorText != null) ...[
          const SizedBox(height: 8),
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

        // Action buttons: Huỷ / Đổi
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _submitting ? null : widget.onClose,
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
            Expanded(
              child: GestureDetector(
                onTap: _submitting ? null : _handleSubmit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _submitting
                        ? const Color(0xFF2F3E2E).withValues(alpha: 0.4)
                        : const Color(0xFF2F3E2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _submitting
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
                          'Đổi',
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

// ---------------------------------------------------------------------------
// Obscured text field used for each password entry
// ---------------------------------------------------------------------------

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.enabled,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      enabled: widget.enabled,
      style: GoogleFonts.quintessential(
        fontSize: 14,
        color: const Color(0xFF2F3E2E),
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: GoogleFonts.quintessential(
          fontSize: 13,
          color: const Color(0xFF8B6F47).withValues(alpha: 0.6),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: const Color(0xFF8B6F47),
          ),
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
  }
}
