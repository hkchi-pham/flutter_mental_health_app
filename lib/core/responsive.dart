/// Responsive layout utilities for Soul Garden.
///
/// Breakpoints (mobile-first):
///   phone  — width < 600 px  (the primary target; all layouts default to this)
///   tablet — 600 px ≤ width ≤ 1024 px
///   desktop— width > 1024 px
///
/// [kMaxContentWidth] is the single source of truth for the app-wide content
/// cap. Any widget that needs to know the band width reads this constant; the
/// actual clamping happens in the [MaterialApp.builder] shell in main.dart.
library;

import 'package:flutter/widgets.dart';

/// Maximum width of the centered content band on wide screens.
///
/// Below this threshold the app fills the screen exactly as it did before the
/// shell was added (ConstrainedBox does not bite). Above it the content is
/// letterboxed within a calm garden-palette side band.
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
/// **Important:** [screenWidth] and [screenHeight] read the raw [MediaQuery]
/// window size — i.e. the full OS window, not the constrained 500 px band.
/// This is intentional for *breakpoint queries* (is this a phone? a tablet?).
/// For layout math that must respect the 500 px band, use [LayoutBuilder] or
/// [BoxConstraints.maxWidth] inside the shell widget.
extension ResponsiveContext on BuildContext {
  /// Raw window width from [MediaQuery] (not the constrained band width).
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
