import 'dart:ui';

/// Every colour of the app icon and the splash, taken from the owner's chosen design (`Icon2.dc.html`, `Splash2.dc.html`). The
/// splash is always in this night look, whatever look the reader chose for the app (spec FR-007), so these do not come from
/// `AppLook`.
abstract final class SplashColors {
  /// The flat colour of the native launch screen and the outer part of the splash gradient.
  static const Color background = Color(0xFF0D1014);

  /// The centre of the splash's radial gradient (the lightest the background gets: contrast is measured against it too).
  static const Color backdropGlow = Color(0xFF17313A);

  /// The name «مصحف الحافظ».
  static const Color name = Color(0xFFECE7DC);

  /// The line under the name.
  static const Color tagline = Color(0xFF9AA4AD);

  /// The thin line at the bottom: its track and its fill.
  static const Color progressTrack = Color(0xFF232A33);
  static const Color progressFill = Color(0xFF6CC4B5);

  /// The two faint rings around the tile's centre.
  static const Color ringNear = Color(0xFF232A33);
  static const Color ringFar = Color(0xFF1B2128);

  /// The icon: the top of its background gradient (the bottom is [background]), the star, the pages, the page lines and the
  /// gold line.
  static const Color tileTop = Color(0xFF1A212A);
  static const Color star = Color(0xFF6CC4B5);
  static const Color pageLeft = Color(0xFFECE7DC);
  static const Color pageRight = Color(0xFFD6D0C1);
  static const Color pageInk = Color(0xFF8A939C);
  static const Color gold = Color(0xFFE3B05A);
}
