import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'mushaf_page.dart';
import 'page_look.dart';

/// One Mushaf page as a card: the thin ring, the paper, the frame and the page text, in the colours of a
/// [PageLook]. The reader, the page picture and the PDF pages all draw this same widget, so they cannot
/// drift apart. The page text fills the card; give it its size from outside.
class MushafPageCard extends StatelessWidget {
  const MushafPageCard({
    super.key,
    required PageData this.data,
    required MushafMeta this.meta,
    required String this.fontFamily,
    this.look = PageLook.screen,
    this.highlightedWordIds = const {},
    this.tintedWordIds = const {},
    this.onWordLongPress,
    this.onPageNumberTap,
  }) : page = null;

  /// The same card while the page font is still loading: the page number only, never the text in another
  /// font (spec FR-008a).
  const MushafPageCard.loading({
    super.key,
    required int this.page,
    this.look = PageLook.screen,
  }) : data = null,
       meta = null,
       fontFamily = null,
       highlightedWordIds = const {},
       tintedWordIds = const {},
       onWordLongPress = null,
       onPageNumberTap = null;

  final PageData? data;
  final MushafMeta? meta;
  final String? fontFamily;
  final int? page;
  final PageLook look;
  final Set<int> highlightedWordIds;

  /// The words of the bookmarked ayat, drawn on [PageLook.bookmarkTint] (feature 013); empty in pictures and PDFs.
  final Set<int> tintedWordIds;
  final void Function(MushafWord word)? onWordLongPress;
  final VoidCallback? onPageNumberTap;

  @override
  Widget build(BuildContext context) {
    final loaded = data;
    final Widget content = loaded == null
        ? MushafPageLoading(page: page!, textColor: look.ink, numberColor: look.numberColor)
        : MushafPage(
            data: loaded,
            meta: meta!,
            fontFamily: fontFamily!,
            textColor: look.ink,
            frameColor: look.frame,
            frameWidth: look.frameWidth,
            bannerColor: look.bannerFill,
            bannerTextColor: look.bannerText,
            bannerStyle: look.bannerStyle,
            bannerRuleColor: look.bannerRule,
            numberColor: look.numberColor,
            endMarkerColor: look.endMarker,
            highlightColor: look.highlight,
            highlightedWordIds: highlightedWordIds,
            tintedWordIds: tintedWordIds,
            tintColor: look.bookmarkTint,
            onWordLongPress: onWordLongPress,
            onPageNumberTap: onPageNumberTap,
          );
    final ring = look.ring;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // Paper with a frame and a thin outer ring, like a printed Mushaf.
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: ring == null ? null : Border.all(color: ring),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: look.paper,
              border: Border.all(color: look.frame, width: look.frameWidth),
              borderRadius: BorderRadius.circular(16),
            ),
            // Room between the text and the frame.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
