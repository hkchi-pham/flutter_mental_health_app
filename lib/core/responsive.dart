/// Responsive layout utilities for Soul Garden.
///
/// Breakpoints (mobile-first):
///   phone  — width < 600 px  (the primary target; all layouts default to this)
///   tablet — 600 px ≤ width ≤ 1024 px
///   desktop— width > 1024 px
///
/// Responsiveness is **per-screen**, not app-wide:
///   • Full-bleed screens (garden, splash, auth backgrounds) render edge-to-edge
///     and scale via `BoxFit.cover` / percentage layout. They must NOT be width
///     capped — the garden background, in particular, must fill 100% of the
///     window width or its grid/items desync from the visible area.
///   • Width-limited screens (chat, journal, shop, settings forms) opt in by
///     wrapping their body in [MaxWidthBox], which centers + caps at
///     [kMaxContentWidth].
library;

import 'package:flutter/widgets.dart';

/// Maximum width of a *width-limited* screen's content on wide windows.
///
/// Applied only by [MaxWidthBox] on screens that opt in (chat, journal, shop,
/// settings). Full-bleed screens ignore this entirely.
const double kMaxContentWidth = 500.0;

/// Coarse screen-size classification derived from the window width.
enum ScreenSize {
  /// width < 600 px — phone portrait; the primary design target.
  phone,

  /// 600 px ≤ width ≤ 1024 px — tablet or large phone in landscape.
  tablet,

  /// width > 1024 px — desktop / web window.
  desktop,
}

/// Classifies a raw pixel [width] into a [ScreenSize] bucket.
ScreenSize classifyWidth(double width) {
  if (width < 600) return ScreenSize.phone;
  if (width <= 1024) return ScreenSize.tablet;
  return ScreenSize.desktop;
}

/// [BuildContext] extensions for responsive queries.
///
/// [screenWidth]/[screenHeight] read the raw [MediaQuery] window size — the
/// full OS window. Full-bleed screens use this directly for percentage layout.
/// Width-limited content lives inside a [MaxWidthBox]; use [LayoutBuilder] /
/// [BoxConstraints.maxWidth] there if you need the capped band width.
extension ResponsiveContext on BuildContext {
  /// Raw window width from [MediaQuery] (the full OS window).
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Raw window height from [MediaQuery].
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Coarse size classification based on [screenWidth].
  ScreenSize get screenSize => classifyWidth(screenWidth);

  /// `true` when the window is narrower than 600 px (phone portrait).
  bool get isPhone => screenSize == ScreenSize.phone;

  /// `true` when the window is between 600 px and 1024 px (tablet).
  bool get isTablet => screenSize == ScreenSize.tablet;

  /// `true` when the window is wider than 1024 px (desktop / web).
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Returns the value matching the current [screenSize], falling back to
  /// [phone] when the size-specific value is not provided.
  ///
  /// Example:
  /// ```dart
  /// double padding = context.responsiveValue(phone: 12, tablet: 24, desktop: 48);
  /// ```
  ///
  /// [phone] is required because it is always the non-null fallback.
  /// [tablet] and [desktop] default to [phone] when omitted.
  T responsiveValue<T>({required T phone, T? tablet, T? desktop}) {
    switch (screenSize) {
      case ScreenSize.desktop:
        return desktop ?? phone;
      case ScreenSize.tablet:
        return tablet ?? phone;
      case ScreenSize.phone:
        return phone;
    }
  }
}

/// Centers [child] and caps its width at [maxWidth] (default [kMaxContentWidth]).
///
/// Use this to wrap the body of *width-limited* screens — chat, journal, shop,
/// settings — whose content should stay compact and not stretch across wide
/// tablet/desktop windows. On narrow phones the cap does not bite, so the
/// content fills the width exactly as before.
///
/// **Do not** use this on full-bleed screens (garden, splash, auth
/// backgrounds): those must render edge-to-edge.
///
/// ```dart
/// Scaffold(body: MaxWidthBox(child: JournalView()));
/// ```
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
  });

  /// The width-limited content.
  final Widget child;

  /// The maximum width the content is allowed to grow to.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
