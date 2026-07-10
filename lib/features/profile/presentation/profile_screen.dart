import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../logic/profile_provider.dart';
import 'widgets/edit_name_dialog.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_settings_section.dart';
import 'widgets/stats_grid.dart';

/// The Profile tab screen.
///
/// Loads [ProfileProvider] data on mount via [addPostFrameCallback] to avoid
/// calling [BuildContext] methods during initState.
///
/// State transitions driven by [ProfileProvider.status]:
///   - [ProfileStatus.loading]  → skeleton header + [StatsGrid.skeleton]
///   - [ProfileStatus.error]    → friendly Vietnamese message + retry button
///   - [ProfileStatus.loaded]   → [ProfileHeader] + [StatsGrid]
///
/// The name-edit flow ([EditNameDialog]) is inserted as a full-screen [Stack]
/// overlay managed in this [State], mirroring the badge/settings popup pattern.
///
/// A placeholder settings slot (`_settingsSlot`) is provided at the bottom of
/// the scroll column so that Plan 13-05 can swap one line without touching the
/// rest of the screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Whether the [EditNameDialog] overlay is currently shown.
  bool _editDialogVisible = false;

  @override
  void initState() {
    super.initState();
    // Load after the first frame so context.read is safe and the Scaffold is
    // fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().load();
    });
  }

  // ── Edit-name overlay ──────────────────────────────────────────────────────

  void _openEditName() {
    if (_editDialogVisible) return;
    setState(() => _editDialogVisible = true);
  }

  void _closeEditName() {
    if (!mounted) return;
    setState(() => _editDialogVisible = false);
  }


  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Main screen content ──────────────────────────────────────────────
        _buildMainContent(context),
        // ── EditNameDialog overlay (shown above everything) ──────────────────
        if (_editDialogVisible)
          Positioned.fill(
            child: Consumer<ProfileProvider>(
              builder: (context, provider, _) {
                return EditNameDialog(
                  initialName: provider.user?.fullname ?? '',
                  onClose: _closeEditName,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE0),
      body: SafeArea(
        child: MaxWidthBox(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Title ──────────────────────────────────────────────
                      _buildTitle(),
                      const SizedBox(height: 24),
                      // ── Body — driven by ProfileStatus ─────────────────────
                      Consumer<ProfileProvider>(
                        builder: (context, provider, _) {
                          return _buildBody(provider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Hồ sơ',
      textAlign: TextAlign.center,
      style: GoogleFonts.quintessential(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2F3E2E),
      ),
    );
  }

  Widget _buildBody(ProfileProvider provider) {
    switch (provider.status) {
      case ProfileStatus.loading:
        return _buildLoadingState();
      case ProfileStatus.error:
        return _buildErrorState(provider);
      case ProfileStatus.loaded:
        return _buildLoadedState(provider);
    }
  }

  // ── Loading state ──────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      children: [
        _SkeletonHeader(),
        const SizedBox(height: 28),
        const StatsGrid.skeleton(),
      ],
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState(ProfileProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: const Color(0xFF8B6F47).withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Không tải được hồ sơ. Thử lại.',
              textAlign: TextAlign.center,
              style: GoogleFonts.quintessential(
                fontSize: 15,
                color: const Color(0xFF5C4A2A),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: provider.load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3E2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Thử lại',
                  style: GoogleFonts.quintessential(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loaded state ───────────────────────────────────────────────────────────

  Widget _buildLoadedState(ProfileProvider provider) {
    return Column(
      children: [
        ProfileHeader(
          user: provider.user!,
          onEdit: _openEditName,
        ),
        const SizedBox(height: 28),
        StatsGrid(user: provider.user!),
        const SizedBox(height: 28),
        ProfileSettingsSection(
          email: provider.user?.email ?? '',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton header — placeholder shown while profile loads
// ---------------------------------------------------------------------------

/// A muted grey-cream placeholder mimicking [ProfileHeader] for the loading
/// state. Animates with a gentle pulsing opacity.
class _SkeletonHeader extends StatefulWidget {
  @override
  State<_SkeletonHeader> createState() => _SkeletonHeaderState();
}

class _SkeletonHeaderState extends State<_SkeletonHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle avatar placeholder
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFD9CBAA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B6F47).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Fullname placeholder bar
            Container(
              width: 160,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFD9CBAA),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            // @username placeholder bar
            Container(
              width: 100,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFFD9CBAA),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
