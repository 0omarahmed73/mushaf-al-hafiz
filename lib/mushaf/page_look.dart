import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// How the surah title of a page is drawn: in a framed banner (Emerald & Gold: a box with an outline, a fill and a
/// star each side) or as the title between two hairlines (Night Reader: no box, no fill).
enum PageBannerStyle { framed, rules }

/// The colours of a drawn Mushaf page. [screen] is Emerald & Gold, the app's own look: the reader, the page picture
/// and the pages of the surah PDF all use the look the owner chose (the black-and-white print look was dropped on
/// 2026-11-20, spec FR-015), [night] is Night Reader. The geometry is the same in any look: a look carries colours and
/// the banner style only, never a size, a padding or a text (Constitution I and II).
class PageLook {
  const PageLook({
    required this.paper,
    required this.ink,
    required this.frame,
    required this.frameWidth,
    required this.bannerText,
    required this.background,
    this.ring,
    this.bannerFill,
    this.bannerStyle = PageBannerStyle.framed,
    this.bannerRule,
    this.numberColor,
    this.highlight = const Color(0x55FFC107),
    this.endMarker,
    this.bookmarkTint = const Color(0x290F766E),
  });

  /// The colour behind the card in a picture or a PDF page: the app's green.
  final Color background;

  /// The thin outer ring around the frame, or null for none.
  final Color? ring;

  final Color paper;
  final Color ink;

  /// Colour and width of the page frame and of the surah banner outline.
  final Color frame;
  final double frameWidth;

  /// Fill of the surah banner, or null for none; and the colour of its title and stars.
  final Color? bannerFill;
  final Color bannerText;

  /// [PageBannerStyle.framed] draws the box (outline [frame], fill [bannerFill], stars); [PageBannerStyle.rules]
  /// draws the title between two 1 px hairlines in [bannerRule], with no box, no fill and no stars.
  final PageBannerStyle bannerStyle;
  final Color? bannerRule;

  /// The colour of the page number, or null for the [ink].
  final Color? numberColor;

  /// The wash behind the long-pressed ayah.
  final Color highlight;

  /// The colour of the ayah-end markers, or null to draw them in the [ink].
  final Color? endMarker;

  /// The light, permanent wash behind the words of an ayah that has a bookmark (feature 013, research D6): another hue
  /// than [highlight] and a weaker wash, so the two are told apart; the highlight replaces it while it lasts.
  final Color bookmarkTint;

  static const PageLook screen = PageLook(
    ring: AppColors.ring,
    paper: AppColors.paper,
    ink: AppColors.ink,
    frame: AppColors.goldDark,
    frameWidth: 2,
    bannerFill: AppColors.green,
    bannerText: AppColors.gold,
    background: AppColors.green,
  );

  /// Emerald & Gold, the look the app has always had.
  static const PageLook emerald = screen;

  /// Night Reader: the page is drawn straight on the dark background. The paper is the background colour and the
  /// frame is fully transparent but keeps its width, so the card's boxes are laid out exactly as in Emerald & Gold and
  /// nothing is painted (spec FR-007, FR-008).
  static const PageLook night = PageLook(
    background: Color(0xFF0D1014),
    paper: Color(0xFF0D1014),
    ink: Color(0xFFECE7DC),
    frame: Color(0x00000000),
    frameWidth: 2,
    bannerText: Color(0xFF6CC4B5),
    bannerStyle: PageBannerStyle.rules,
    bannerRule: Color(0xFF2B343D),
    numberColor: Color(0xFF85909B),
    highlight: Color(0x4D6CC4B5),
    endMarker: Color(0xFF6CC4B5),
    bookmarkTint: Color(0x24E4C877),
  );
}
