import '../mushaf/page_look.dart';
import '../theme.dart';

/// Which of the two looks the owner chose (spec FR-001, FR-016). It is stored by [name] in the settings table
/// under one key; anything that is not one of the two names, or nothing at all, is read as the default.
enum LookChoice {
  /// «زمردي وذهبي»: today's look, deep green with an ivory page and gold accents.
  emerald,

  /// «القارئ الليلي»: near-black with charcoal cards and a teal accent.
  night;

  /// The colours and shapes of this look.
  AppLook get look => switch (this) {
    LookChoice.emerald => AppLook.emerald,
    LookChoice.night => AppLook.night,
  };

  /// How a Mushaf page is drawn in this look: on the ivory card in Emerald & Gold, straight on the dark background in
  /// Night Reader. The reader, the page picture and the surah PDF all use it.
  PageLook get pageLook => switch (this) {
    LookChoice.emerald => PageLook.screen,
    LookChoice.night => PageLook.night,
  };

  /// The look the app has until the owner chooses another.
  static const LookChoice defaultChoice = LookChoice.emerald;

  /// Reads a stored value. Never throws: null, empty, unknown or differently cased text is [defaultChoice], so an
  /// old or edited backup cannot fail an import or an app start.
  static LookChoice parse(String? raw) {
    for (final c in LookChoice.values) {
      if (c.name == raw) return c;
    }
    return defaultChoice;
  }
}
