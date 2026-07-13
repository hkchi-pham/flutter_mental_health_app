import 'package:flutter/material.dart';

import '../../data/profile_user.dart';

/// Default Komo avatar path used when [ProfileUser.avatar] is empty.
const String _komoAvatarPath = 'assets/profile/komo_avatar_default_@3x.png';

/// Avatar frame overlay path (decorative frame drawn on top of the avatar).
const String _avatarFramePath = 'assets/profile/avatar_frame_@3x.png';

/// Header background image path.
const String _headerBgPath = 'assets/screens/profile_header_background.png';

/// Fallback gradient colours used when the header image fails to load.
const _gradientStart = Color(0xFF4CAF50);
const _gradientEnd = Color(0xFFA5D6A7);

/// Profile header section.
///
/// Renders a rounded container with the real header background image
/// ([_headerBgPath]), clipped with rounded corners (24 px radius). Falls back
/// to a sage→light-green gradient if the image is unavailable.
///
/// Fix 3: Height is derived from available width via [LayoutBuilder] so the
///   header scales proportionally across phone→tablet widths.
/// Fix 4: Uses Image.asset for the header background instead of a plain
///   gradient; ClipRRect ensures the image corners match the card.
///
/// Contents:
///   - Centered avatar (framed by [_avatarFramePath]), tappable to open edit.
///   - User fullname (24 sp bold #3E2723, centered).
///   - User email (14 sp regular #5D4037, centered).
///   - Subtle "tap to edit" hint row.
///
/// Tapping the avatar OR the name triggers [onEdit].
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEdit,
  });

  final ProfileUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale header height proportionally: ~55% of available width.
        // Clamped so it stays reasonable on tiny and very wide screens.
        final double headerHeight =
            (constraints.maxWidth * 0.55).clamp(180.0, 300.0);

        return Container(
          width: double.infinity,
          height: headerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Background: real image with gradient fallback ──────────
                _buildBackground(),
                // ── Foreground content ────────────────────────────────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Framed avatar ─────────────────────────────────
                        _buildFramedAvatar(),
                        const SizedBox(height: 12),
                        // ── Fullname ──────────────────────────────────────
                        Text(
                          user.fullname.isEmpty ? '—' : user.fullname,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ── Email ─────────────────────────────────────────
                        Text(
                          user.email.isEmpty ? '—' : user.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // ── Tap-to-edit hint ──────────────────────────────
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: const Color(0xFF3E2723)
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Chỉnh sửa tên',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF3E2723)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Attempts to load the real header background image.
  /// Falls back to a sage→light-green gradient on any load error.
  Widget _buildBackground() {
    return Image.asset(
      _headerBgPath,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gradientStart, _gradientEnd],
          ),
        ),
      ),
    );
  }

  Widget _buildFramedAvatar() {
    // Determine the inner avatar source.
    final avatarSrc =
        user.avatar.isNotEmpty ? user.avatar : _komoAvatarPath;

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner avatar — circular clipped
          ClipOval(
            child: Container(
              width: 88,
              height: 88,
              color: const Color(0xFFDCEDC8),
              child: Image.asset(
                avatarSrc,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  if (avatarSrc != _komoAvatarPath) {
                    return Image.asset(
                      _komoAvatarPath,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person,
                        size: 52,
                        color: Color(0xFF8D6E63),
                      ),
                    );
                  }
                  return const Icon(
                    Icons.person,
                    size: 52,
                    color: Color(0xFF8D6E63),
                  );
                },
              ),
            ),
          ),
          // Decorative frame overlay
          Positioned.fill(
            child: Image.asset(
              _avatarFramePath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
