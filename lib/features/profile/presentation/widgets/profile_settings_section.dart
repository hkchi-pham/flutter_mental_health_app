import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../onboarding/data/onboarding_store.dart';
import 'change_password_dialog.dart';

// TODO: source app version from package_info_plus when the dep is added
const _appVersion = '1.0.0';

// ── Color constants ───────────────────────────────────────────────────────────
const _primary = Color(0xFF4CAF50);
const _primaryLight = Color(0xFFA5D6A7);
const _textPrimary = Color(0xFF3E2723);
const _textSecondary = Color(0xFF8D6E63);
const _dividerColor = Color(0xFFE6D5A8);
const _cardColor = Color(0xFFFFFDF5);
const _dangerColor = Color(0xFFE57373);

/// The "Cài đặt" settings section rendered below the stats grid.
///
/// Tiles (in order, 56 px each):
///   1. Thông báo — icon_settings_noti, trailing Switch (SharedPreferences).
///   2. Đổi mật khẩu — icon_settings_password, trailing chevron.
///   3. Về Soul Garden — icon_setting_about, trailing chevron.
///
/// Logout button below the section with btn_logout_@3x.png background
/// (or pill #E57373 fallback).
///
/// Footer: version + tagline.
class ProfileSettingsSection extends StatefulWidget {
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
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khu vườn chữa lành của bạn',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 14,
              color: _textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: _dividerColor, thickness: 1),
          const SizedBox(height: 10),
          Text(
            'Phiên bản $_appVersion',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Được tạo bởi nhóm Soul Garden',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 12,
              color: _textSecondary,
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
          },
        ),
      ),
    );
    overlay.insert(entry);
  }

  // ── Hidden dev reset ───────────────────────────────────────────────────────

  Future<void> _resetOnboarding() async {
    await OnboardingStore().reset();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đặt lại phần giới thiệu. Khởi động lại ứng dụng để xem lại.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ── Framed-dialog helper ───────────────────────────────────────────────────

  void _showFramedDialog({required String title, required Widget child}) {
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
        // ── Section heading ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Cài đặt',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _primaryLight,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // ── Settings card ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Notifications toggle
              _SettingsTile(
                iconAsset: 'assets/profile/icon_settings_noti_@3x.png',
                fallbackIcon: Icons.notifications_outlined,
                label: 'Thông báo',
                trailing: _loadedPrefs
                    ? Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeThumbColor: _primary,
                        activeTrackColor: _primaryLight,
                        inactiveThumbColor: _textSecondary,
                        inactiveTrackColor: _dividerColor,
                      )
                    : const SizedBox(
                        width: 36,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      ),
              ),
              const Divider(height: 1, thickness: 1, color: _dividerColor),
              // 2. Change password
              _SettingsTile(
                iconAsset: 'assets/profile/icon_settings_password_@3x.png',
                fallbackIcon: Icons.lock_outline,
                label: 'Đổi mật khẩu',
                onTap: _openChangePassword,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: _textSecondary,
                  size: 20,
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _dividerColor),
              // 3. About
              _SettingsTile(
                iconAsset: 'assets/profile/icon_setting_about_@3x.png',
                fallbackIcon: Icons.info_outline,
                label: 'Về Soul Garden',
                onTap: _showAbout,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: _textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // ── Logout button ───────────────────────────────────────────────────
        const SizedBox(height: 24),
        _LogoutButton(onTap: _showLogoutConfirm),

        // ── Footer ──────────────────────────────────────────────────────────
        const SizedBox(height: 24),
        GestureDetector(
          onLongPress: _resetOnboarding,
          child: const Text(
            'v$_appVersion',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Made with 💚 in Vietnam',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Settings tile
// ---------------------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  final String iconAsset;
  final IconData fallbackIcon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                width: 24,
                height: 24,
                errorBuilder: (_, _, _) => Icon(
                  fallbackIcon,
                  size: 22,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout button
// ---------------------------------------------------------------------------

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image — pill btn_logout_@3x.png.
                // BoxFit.contain keeps the pill graphic fully visible
                // (never cropped) at any screen width.
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    'assets/profile/btn_logout_@3x.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      decoration: BoxDecoration(
                        color: _dangerColor,
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
                // Label centered over the button
                const Center(
                  child: Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Framed overlay dialog (About / Logout confirm)
// ---------------------------------------------------------------------------

/// 200ms scale+fade entrance — mirrors [EditNameDialog] / badge-popup pattern.
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
                onTap: () {},
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
                Positioned(
                  top: popupHeight * creamTopFrac,
                  bottom: popupHeight * creamBottomFrac,
                  left: popupWidth * creamLeftFrac,
                  right: popupWidth * creamRightFrac,
                  child: Container(color: const Color(0xFFEBDDB8)),
                ),
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
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(
                          color: _dividerColor,
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
  final Future<void> Function() onConfirm;
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
            color: _textSecondary,
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
                      color: _dividerColor,
                    ),
                  ),
                  child: Text(
                    'Huỷ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quintessential(
                      fontSize: 15,
                      color: _textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _loggingOut ? null : _handleConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _loggingOut
                        ? _dangerColor.withValues(alpha: 0.4)
                        : _dangerColor,
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
