import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/profile_provider.dart';
import 'widgets/edit_name_dialog.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_settings_section.dart';
import 'widgets/stats_grid.dart';

// ── Design palette ────────────────────────────────────────────────────────────
const _bgColor = Color(0xFFFFF8E1);
const _textSecondary = Color(0xFF8D6E63);
const _primary = Color(0xFF4CAF50);
const _dividerColor = Color(0xFFE6D5A8);

/// The Profile tab screen.
///
/// Loads [ProfileProvider] data on mount via [addPostFrameCallback].
///
/// State transitions:
///   - [ProfileStatus.loading] → skeleton header + [StatsGrid.skeleton]
///   - [ProfileStatus.error]   → friendly Vietnamese message + retry button
///   - [ProfileStatus.loaded]  → [ProfileHeader] + [StatsGrid] + settings
///
/// Full-screen background: #FFF8E1 (warm cream).
/// Layout: single ScrollView, full-screen width, 16 px horizontal padding.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().load();
    });
  }

  void _openEditName() {
    if (_editDialogVisible) return;
    setState(() => _editDialogVisible = true);
  }

  void _closeEditName() {
    if (!mounted) return;
    setState(() => _editDialogVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMainContent(context),
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
      backgroundColor: _bgColor,
      body: SafeArea(
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
                    Consumer<ProfileProvider>(
                      builder: (context, provider, _) =>
                          _buildBody(provider),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        const _SkeletonHeader(),
        const SizedBox(height: 20),
        const StatsGrid.skeleton(),
      ],
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState(ProfileProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: _textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Không tải được hồ sơ. Thử lại.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: provider.load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header
        ProfileHeader(
          user: provider.user!,
          onEdit: _openEditName,
        ),
        const SizedBox(height: 20),
        // 2. Stats grid (3 × 2)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: StatsGrid(user: provider.user!),
        ),
        const SizedBox(height: 20),
        // 3. Divider
        _buildDivider(),
        const SizedBox(height: 20),
        // 4. Settings + logout + footer
        ProfileSettingsSection(
          email: provider.user?.email ?? '',
        ),
      ],
    );
  }

  Widget _buildDivider() {
    // The branch asset has a natural display width of ~330 logical pixels.
    // On a phone (≈360dp after 16px padding on each side → ~328dp) this means
    // exactly 1 branch fills the row.  On an iPad (≈700dp) → 2 branches.
    // On a wide desktop (≈1000+dp) → 3+ branches.
    //
    // Implementation: LayoutBuilder measures the available width, computes how
    // many branch copies are needed, lays them in a Row, and clips the last
    // one so it never overflows.  BoxFit.contain at a fixed 56px height keeps
    // each branch at its natural proportions without stretching.
    const double branchHeight = 56.0;
    const double branchDisplayWidth = 330.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final int count =
            (availableWidth / branchDisplayWidth).ceil().clamp(1, 8);

        return ClipRect(
          child: SizedBox(
            width: availableWidth,
            height: branchHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(count, (_) {
                return Image.asset(
                  'assets/profile/profile_divider_@3x.png',
                  width: branchDisplayWidth,
                  height: branchHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => SizedBox(
                    width: branchDisplayWidth,
                    height: branchHeight,
                    child: const Divider(
                      color: _dividerColor,
                      thickness: 1,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton header — new-design style
// ---------------------------------------------------------------------------

/// Pulsing placeholder matching the new gradient-header shape while loading.
class _SkeletonHeader extends StatefulWidget {
  const _SkeletonHeader();

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
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFA5D6A7),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar placeholder
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFF81C784),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 14),
              // Name bar
              Container(
                width: 160,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              // Email bar
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
