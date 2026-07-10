import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/data/auth_repository.dart';
import 'change_password_dialog.dart';

// TODO: source app version from package_info_plus when the dep is added
const _appVersion = '2.1.0';

/// A "Cài đặt" settings section for the Profile screen.
///
/// Contains five tiles — in order:
///   1. Notifications toggle (persists to [SharedPreferences])
///   2. Change password (opens [ChangePasswordDialog])
///   3. Email (read-only display)
///   4. About "Về Soul Garden" (framed dialog with version + credits)
///   5. Logout (confirm dialog → clears token, AuthGate routes to login)
///
/// Dark-mode and language tiles are deferred per SET-01 scope note.
class ProfileSettingsSection extends StatefulWidget {
  /// The authenticated user's email address (read-only display).
  final String email;

  const ProfileSettingsSection({super.key, required this.email});

  @override
  State<ProfileSettingsSection> createState() => _ProfileSettingsSectionState();
}

class _ProfileSettingsSectionState extends State<ProfileSettingsSection> {
  static const _notifKey = 'profile_notifications_enabled';

  bool _notificationsEnabled = true;
  bool _loadedPrefs = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationsPref();
  }

  Future<void> _loadNotificationsPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notifKey) ?? true;
      _loadedPrefs = true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, value);
  }

  // ── Change password ────────────────────────────────────────────────────────

  void _openChangePassword() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ChangePasswordDialog(
        onClose: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  // ── About dialog ───────────────────────────────────────────────────────────

  void _showAbout() {
    _showFramedDialog(
      title: 'Về Soul Garden',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Soul Garden',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2F3E2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khu vườn chữa lành của bạn',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 14,
              color: const Color(0xFF5C4A2A),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: const Color(0xFF8B6F47).withValues(alpha: 0.4),
            thickness: 1,
          ),
          const SizedBox(height: 10),
          Text(
            'Phiên bản $_appVersion',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 13,
              color: const Color(0xFF5C4A2A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Được tạo bởi nhóm Soul Garden',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 12,
              color: const Color(0xFF8B6F47),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  void _showLogoutConfirm() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FramedOverlayDialog(
        title: 'Đăng xuất?',
        onClose: () => entry.remove(),
        child: _LogoutDialogContent(
          onClose: () => entry.remove(),
          onConfirm: () async {
            await context.read<AuthRepository>().logout();
            // AuthGate detects cleared session and routes to login automatically
          },
        ),
      ),
    );
    overlay.insert(entry);
  }

  // ── Framed-dialog helper ───────────────────────────────────────────────────

  /// Inserts a framed popup using the badge/settings OverlayEntry pattern.
  void _showFramedDialog({
    required String title,
    required Widget child,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FramedOverlayDialog(
        title: title,
        onClose: () => entry.remove(),
        child: child,
      ),
    );
    overlay.insert(entry);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section heading
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Cài đặt',
            style: GoogleFonts.quintessential(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2F3E2E),
            ),
          ),
        ),

        // ── 1. Notifications toggle ─────────────────────────────────────────
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Thông báo',
          trailing: _loadedPrefs
              ? Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeThumbColor: const Color(0xFF2F3E2E),
                  activeTrackColor: const Color(0xFFCDE0B4),
                  inactiveThumbColor: const Color(0xFF8B6F47),
                  inactiveTrackColor: const Color(0xFFD9C9A8),
                )
              : const SizedBox(
                  width: 36,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
        ),

        const SizedBox(height: 8),

        // ── 2. Change password ──────────────────────────────────────────────
        _SettingsTile(
          icon: Icons.lock_outline,
          label: 'Đổi mật khẩu',
          onTap: _openChangePassword,
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF8B6F47),
            size: 20,
          ),
        ),

        const SizedBox(height: 8),

        // ── 3. Email (read-only) ────────────────────────────────────────────
        _SettingsTile(
          icon: Icons.email_outlined,
          label: 'Email',
          trailing: Text(
            widget.email.isNotEmpty ? widget.email : '—',
            style: GoogleFonts.quintessential(
              fontSize: 13,
              color: const Color(0xFF8B6F47),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 8),

        // ── 4. About ────────────────────────────────────────────────────────
        _SettingsTile(
          icon: Icons.info_outline,
          label: 'Về Soul Garden',
          onTap: _showAbout,
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF8B6F47),
            size: 20,
          ),
        ),

        const SizedBox(height: 8),

        // ── 5. Logout ───────────────────────────────────────────────────────
        _SettingsTile(
          icon: Icons.logout,
          label: 'Đăng xuất',
          onTap: _showLogoutConfirm,
          labelColor: const Color(0xFFB03A2E),
          iconColor: const Color(0xFFB03A2E),
          borderColor: const Color(0xFFB03A2E).withValues(alpha: 0.4),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared tile widget
// ---------------------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? labelColor;
  final Color? iconColor;
  final Color? borderColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.labelColor,
    this.iconColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor = labelColor ?? const Color(0xFF2F3E2E);
    final effectiveIconColor = iconColor ?? const Color(0xFF5C4A2A);
    final effectiveBorderColor =
        borderColor ?? const Color(0xFF8B6F47).withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5ECD8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveBorderColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: effectiveIconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.quintessential(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: effectiveLabelColor,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Framed overlay dialog (About / Logout confirm)
// ---------------------------------------------------------------------------

/// Stateful widget implementing the 200ms scale+fade entrance.
/// Matches the [SettingsMenuPopup] / [EditNameDialog] pattern exactly:
///   frame_info_page_@2x.png, cream fill 0xFFEBDDB8, cancel button in gutter.
class _FramedOverlayDialog extends StatefulWidget {
  final String title;
  final VoidCallback onClose;
  final Widget child;

  const _FramedOverlayDialog({
    required this.title,
    required this.onClose,
    required this.child,
  });

  @override
  State<_FramedOverlayDialog> createState() => _FramedOverlayDialogState();
}

class _FramedOverlayDialogState extends State<_FramedOverlayDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _backdrop;

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
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // cancel-only — backdrop absorbs taps
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
    final popupWidth = (mq.size.width * 0.80).clamp(260.0, 400.0);
    final popupHeight = (mq.size.height * 0.42).clamp(240.0, 380.0);

    const double creamLeftFrac = 0.0938;
    const double creamRightFrac = 0.0928;
    const double creamTopFrac = 0.0775;
    const double creamBottomFrac = 0.07;

    const double padLeftFrac = 0.11;
    const double padRightFrac = 0.11;
    const double padTopFrac = 0.10;
    const double padBottomFrac = 0.10;

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
                // Content
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      popupWidth * padLeftFrac,
                      popupHeight * padTopFrac,
                      popupWidth * padRightFrac,
                      popupHeight * padBottomFrac,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.title,
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
                        Expanded(child: widget.child),
                      ],
                    ),
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
              onTap: widget.onClose,
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
}

// ---------------------------------------------------------------------------
// Logout dialog content
// ---------------------------------------------------------------------------

class _LogoutDialogContent extends StatefulWidget {
  /// Called when the user confirms logout (after AuthRepository.logout()).
  final Future<void> Function() onConfirm;

  /// Called when the user cancels — removes the overlay entry.
  final VoidCallback onClose;

  const _LogoutDialogContent({
    required this.onConfirm,
    required this.onClose,
  });

  @override
  State<_LogoutDialogContent> createState() => _LogoutDialogContentState();
}

class _LogoutDialogContentState extends State<_LogoutDialogContent> {
  bool _loggingOut = false;

  Future<void> _handleConfirm() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await widget.onConfirm();
    // AuthGate routes to login; widget may be unmounted before this line.
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bạn có chắc muốn đăng xuất không?',
          textAlign: TextAlign.center,
          style: GoogleFonts.quintessential(
            fontSize: 14,
            color: const Color(0xFF5C4A2A),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _loggingOut ? null : widget.onClose,
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
                onTap: _loggingOut
                    ? null
                    : _handleConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _loggingOut
                        ? const Color(0xFFB03A2E).withValues(alpha: 0.4)
                        : const Color(0xFFB03A2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _loggingOut
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
                          'Đăng xuất',
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
