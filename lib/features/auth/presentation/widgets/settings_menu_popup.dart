import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/auth_repository.dart';

/// Framed settings/menu popup shown from the garden top bar.
///
/// Contains a Logout action that clears the session — the AuthGate then routes
/// back to the login screen automatically on the next build.
///
/// Entrance: 200ms easeOut scale (0.9→1.0) + content fade (0→1) + backdrop
/// alpha (0→0.5) — mirrors the BadgePopup / _InfoPopup pattern exactly.
/// Cancel-only dismissal: backdrop is a tap-absorber; only the X button or
/// Logout dismisses the popup.
///
/// Future profile/settings items can be added below the Logout row.
class SettingsMenuPopup extends StatefulWidget {
  final VoidCallback onClose;

  const SettingsMenuPopup({super.key, required this.onClose});

  @override
  State<SettingsMenuPopup> createState() => _SettingsMenuPopupState();
}

class _SettingsMenuPopupState extends State<SettingsMenuPopup>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _backdrop;

  bool _loggingOut = false;

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

  Future<void> _handleLogout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await context.read<AuthRepository>().logout();
    if (!mounted) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        return Stack(
          children: [
            // 1. Dark backdrop — taps absorbed but do NOT dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // intentionally a no-op; only X / Logout dismisses
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
    final popupWidth = (mq.size.width * 0.75).clamp(260.0, 380.0);
    final popupHeight = (mq.size.height * 0.38).clamp(220.0, 340.0);

    // Cream fill bezel — tight to the frame's visible cavity (matches Phase 6
    // frame_info_page measurements).
    const double creamLeftFrac = 0.0938;
    const double creamRightFrac = 0.0928;
    const double creamTopFrac = 0.0775;
    const double creamBottomFrac = 0.07;

    // Content padding — slightly looser than cream so text doesn't touch bezel.
    const double padLeftFrac = 0.11;
    const double padRightFrac = 0.11;
    const double padTopFrac = 0.10;
    const double padBottomFrac = 0.10;

    // Gutter for the cancel button — sits outside the popup frame to the right.
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
                // Cream interior fill — covers the whole cavity.
                Positioned(
                  top: popupHeight * creamTopFrac,
                  bottom: popupHeight * creamBottomFrac,
                  left: popupWidth * creamLeftFrac,
                  right: popupWidth * creamRightFrac,
                  child: Container(color: const Color(0xFFEBDDB8)),
                ),
                // Frame background image — wooden border sits on top of cream.
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
          // Cancel button — in the right gutter, outside the popup frame.
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

  Widget _buildInterior(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Text(
          'Settings',
          textAlign: TextAlign.center,
          style: GoogleFonts.quintessential(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3E2E),
          ),
        ),
        const SizedBox(height: 16),

        // Divider below title
        Divider(
          color: const Color(0xFF8B6F47).withValues(alpha: 0.4),
          thickness: 1,
        ),
        const SizedBox(height: 12),

        // --- Logout row ---
        GestureDetector(
          onTap: _loggingOut ? null : _handleLogout,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECD8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF8B6F47).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loggingOut)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2F3E2E),
                    ),
                  )
                else
                  Image.asset(
                    'assets/ui_icons/icons/setting_icon_@3x.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.logout,
                      size: 20,
                      color: Color(0xFF2F3E2E),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _loggingOut ? 'Logging out…' : 'Log Out',
                  style: GoogleFonts.quintessential(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2F3E2E),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- Room for future profile / settings items (deferred to later phase) ---

        const Spacer(),
      ],
    );
  }
}
