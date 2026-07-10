import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/profile_user.dart';

/// The Komo avatar path used as the default profile picture.
///
/// Photo upload is deferred (no file-storage infrastructure in this phase).
/// The edit flow edits the NAME only — no image picker.
const String komoAssetPath = 'assets/ui_icons/icons/komo_avatar_@3x.png';

/// Profile header widget: circle avatar (default Komo icon), fullname, and
/// read-only @username.
///
/// Wrapping the avatar + name in a [GestureDetector] so that tapping either
/// one calls [onEdit] (per success criterion: "tap avatar OR name opens the
/// edit modal").
///
/// If [ProfileUser.avatar] is a non-empty string it is attempted first, with a
/// fallback to the Komo default. Every [Image.asset] call has an errorBuilder.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEdit,
  });

  /// The loaded profile data providing fullname, userName, and optional avatar.
  final ProfileUser user;

  /// Called when the user taps the avatar or the name — opens the edit modal.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Circle avatar ───────────────────────────────────────────────
          _buildAvatar(),
          const SizedBox(height: 12),
          // ── Full name ───────────────────────────────────────────────────
          Text(
            user.fullname.isEmpty ? '—' : user.fullname,
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2F3E2E),
            ),
          ),
          const SizedBox(height: 4),
          // ── @username (read-only) ───────────────────────────────────────
          Text(
            '@${user.userName}',
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 15,
              color: const Color(0xFF8B6F47),
            ),
          ),
          const SizedBox(height: 4),
          // ── Subtle "tap to edit" hint ────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 14,
                color: const Color(0xFF8B6F47).withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Chỉnh sửa tên',
                style: GoogleFonts.quintessential(
                  fontSize: 12,
                  color: const Color(0xFF8B6F47).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    // Use user.avatar if it looks like a valid path/URL; otherwise fall back to
    // the Komo default.
    final avatarSource =
        (user.avatar.isNotEmpty) ? user.avatar : komoAssetPath;

    return ClipOval(
      child: Container(
        width: 96,
        height: 96,
        color: const Color(0xFFEBDDB8),
        child: Image.asset(
          avatarSource,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            // If the avatar path fails, try the Komo default before giving up.
            if (avatarSource != komoAssetPath) {
              return Image.asset(
                komoAssetPath,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.person,
                  size: 56,
                  color: Color(0xFF8B6F47),
                ),
              );
            }
            return const Icon(
              Icons.person,
              size: 56,
              color: Color(0xFF8B6F47),
            );
          },
        ),
      ),
    );
  }
}
