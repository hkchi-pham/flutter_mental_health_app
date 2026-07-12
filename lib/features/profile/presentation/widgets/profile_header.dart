import 'package:flutter/material.dart';

import '../../data/profile_user.dart';

/// Default Komo avatar path used when [ProfileUser.avatar] is empty.
const String _komoAvatarPath = 'assets/profile/komo_avatar_default_@3x.png';

/// Avatar frame overlay path (decorative frame drawn on top of the avatar).
const String _avatarFramePath = 'assets/profile/avatar_frame_@3x.png';

/// Profile header section.
///
/// Renders a ~250 px tall rounded gradient container (sage green → light green,
/// since profile_header_bg.png is not available) with:
///   - Centered avatar (framed by [_avatarFramePath]), tappable to open edit.
///   - User fullname (24 sp bold #3E2723, centered).
///   - User email (14 sp regular #8D6E63, centered).
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4CAF50), Color(0xFFA5D6A7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onEdit,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Framed avatar ─────────────────────────────────────────────
            _buildFramedAvatar(),
            const SizedBox(height: 14),
            // ── Fullname ──────────────────────────────────────────────────
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
            // ── Email ─────────────────────────────────────────────────────
            Text(
              user.email.isEmpty ? '—' : user.email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            // ── Tap-to-edit hint ──────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 13,
                  color: const Color(0xFF3E2723).withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Chỉnh sửa tên',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF3E2723).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
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
