import 'package:material_ui/material_ui.dart';

/// The "Emerald & Gold" look (design canvas, direction C): a deep green app, an ivory Mushaf page
/// with a gold frame, gold accents.
abstract final class AppColors {
  static const Color green = Color(0xFF0E3B30);
  static const Color greenDeep = Color(0xFF0A2D25);
  static const Color greenLine = Color(0xFF1E5646);
  static const Color paper = Color(0xFFFBF5E3);
  static const Color ink = Color(0xFF14231D);
  static const Color gold = Color(0xFFE4C877);
  static const Color goldDark = Color(0xFFB8923A);
  static const Color ivory = Color(0xFFF3EBCB);
  static const Color muted = Color(0xFFE8DDB5);
  static const Color ring = Color(0xFF5E7F6F);
}

/// Heading font: Cairo bold, the interface font (the owner, 2026-11-26). Reem Kufi is kept only for the surah title
/// in the Mushaf page (`kTitleFont`), so the page looks as before.
const String kHeadingFont = 'Cairo';

/// Interface font: Cairo, which draws Arabic and Latin text and digits in one family
/// (static Regular 400, Medium 500, SemiBold 600, Bold 700).
const String kUiFont = 'Cairo';

/// Bold for the variable title font (Reem Kufi).
const List<FontVariation> kBoldVariation = [FontVariation('wght', 700)];

/// A heading style in [kHeadingFont], bold.
TextStyle headingStyle(double size, Color color) => TextStyle(
  fontFamily: kHeadingFont,
  fontWeight: FontWeight.w700,
  fontSize: size,
  color: color,
);

/// A colour pair the look is held to: [fg] must reach [min] contrast against [bg] (4.5 for text, 3.0 for large
/// text, icons and the border of a control). See `docs/design/night-reader.md` and spec FR-012.
typedef LookPair = ({String name, Color fg, Color bg, double min});

/// One complete look of the app (spec 004): the colours and the shapes every screen draws with. Screens read it
/// through `context.look`; the Mushaf page has its own `PageLook` for the same two looks. [AppLook.emerald] holds
/// exactly the values the app had before the second look existed.
@immutable
class AppLook extends ThemeExtension<AppLook> {
  const AppLook({
    required this.background,
    required this.barFill,
    required this.barBorder,
    required this.line,
    required this.heading,
    required this.accent,
    required this.accentAlt,
    required this.text,
    required this.textSecondary,
    required this.textDim,
    required this.cardFill,
    required this.cardInk,
    required this.cardMuted,
    required this.cardBorder,
    required this.cardBorderStrong,
    required this.cardBorderActive,
    required this.cardDivider,
    required this.cardDisabled,
    required this.controlBorder,
    required this.primaryFill,
    required this.onPrimary,
    required this.doneFill,
    required this.onDone,
    required this.ring,
    required this.cardRadius,
    required this.strongBorderWidth,
    required this.pillShapes,
    required this.roundAddButton,
    required this.dotMarkers,
    required this.floatingBar,
  });

  /// Scaffold, app bar, sheets and dialogs.
  final Color background;

  /// The reader's bottom bar.
  final Color barFill;
  final Color barBorder;

  /// Hairlines, dividers and inactive slider tracks.
  final Color line;

  /// Screen and sheet titles.
  final Color heading;

  /// Icons, selected states, links and accent text.
  final Color accent;

  /// The second accent: progress bars and emblem details.
  final Color accentAlt;

  /// Body text, captions and quiet text on the background.
  final Color text;
  final Color textSecondary;
  final Color textDim;

  /// Cards, rows and panels, and what is drawn on them.
  final Color cardFill;
  final Color cardInk;
  final Color cardMuted;
  final Color cardBorder;
  final Color cardBorderStrong;
  final Color cardBorderActive;
  final Color cardDivider;
  final Color cardDisabled;

  /// The border of a control (the add button, an outlined button, an unselected option).
  final Color controlBorder;

  /// Filled buttons and what is drawn on them; the «تم» pill on a card.
  final Color primaryFill;
  final Color onPrimary;
  final Color doneFill;
  final Color onDone;

  /// The thin ring of the About emblem.
  final Color ring;

  final double cardRadius;

  /// The border width of the today panel, About and the PDF strip.
  final double strongBorderWidth;

  /// Buttons and tags are pills.
  final bool pillShapes;

  /// The add button is a circle instead of a rounded square.
  final bool roundAddButton;

  /// A wird's marker is a round dot instead of a rotated square.
  final bool dotMarkers;

  /// The reader's bottom bar floats as a rounded pill inside its slot.
  final bool floatingBar;

  /// A button's corner radius: [own] (the screen's own value) unless the look uses pills.
  double buttonRadius(double own) => pillShapes ? 999 : own;

  /// A tag's corner radius.
  double tagRadius(double own) => pillShapes ? 999 : own;

  /// Whether the cards of this look are dark (Night Reader) rather than ivory: what decides if a colour has to be
  /// lifted to be seen on them, and if the transient surfaces (snack bar, dialog, menu, tooltip) are charcoal
  /// instead of the theme's light defaults.
  bool get darkCards => cardFill.computeLuminance() < 0.18;

  /// The corner radius of a row or panel that sits on a sheet (a menu row, a reading panel, a bookmark): [own]
  /// (the screen's own value) unless the look uses pills, where every one of them has the card radius.
  double rowRadius(double own) => pillShapes ? cardRadius : own;

  /// Today's look: deep green, ivory cards, gold accents (design direction C).
  static const AppLook emerald = AppLook(
    background: AppColors.green,
    barFill: AppColors.greenDeep,
    barBorder: AppColors.greenLine,
    line: AppColors.greenLine,
    heading: AppColors.gold,
    accent: AppColors.gold,
    accentAlt: AppColors.goldDark,
    text: AppColors.ivory,
    textSecondary: AppColors.muted,
    textDim: Color(0xBFE8DDB5),
    cardFill: AppColors.paper,
    cardInk: AppColors.ink,
    cardMuted: Color(0xFF2C4A3F),
    cardBorder: Color(0xFFCDBE8E),
    cardBorderStrong: AppColors.goldDark,
    cardBorderActive: AppColors.gold,
    cardDivider: Color(0xFFE2D6A9),
    cardDisabled: Color(0xFF8A8F86),
    controlBorder: AppColors.goldDark,
    primaryFill: AppColors.gold,
    onPrimary: AppColors.green,
    doneFill: AppColors.green,
    onDone: Color(0xFFF3E3A6),
    ring: AppColors.ring,
    cardRadius: 16,
    strongBorderWidth: 2,
    pillShapes: false,
    roundAddButton: false,
    dotMarkers: false,
    floatingBar: false,
  );

  /// «القارئ الليلي»: near-black, charcoal cards, teal accent (design direction B). `textDim` and
  /// `controlBorder` are lighter than the design's values, which miss 4.5:1 and 3:1.
  static const AppLook night = AppLook(
    background: Color(0xFF0D1014),
    barFill: Color(0xFF161B22),
    barBorder: Color(0xFF232A33),
    line: Color(0xFF2B343D),
    heading: Color(0xFFECE7DC),
    accent: Color(0xFF6CC4B5),
    accentAlt: Color(0xFFE3B05A),
    text: Color(0xFFECE7DC),
    textSecondary: Color(0xFF9AA4AD),
    textDim: Color(0xFF85909B),
    cardFill: Color(0xFF161B22),
    cardInk: Color(0xFFECE7DC),
    cardMuted: Color(0xFF9AA4AD),
    cardBorder: Color(0xFF232A33),
    cardBorderStrong: Color(0xFF232A33),
    cardBorderActive: Color(0xFF6CC4B5),
    cardDivider: Color(0xFF232A33),
    cardDisabled: Color(0xFF6B7782),
    controlBorder: Color(0xFF5F6B76),
    primaryFill: Color(0xFF6CC4B5),
    onPrimary: Color(0xFF08201C),
    doneFill: Color(0xFF6CC4B5),
    onDone: Color(0xFF08201C),
    ring: Color(0xFF46525E),
    cardRadius: 20,
    strongBorderWidth: 1,
    pillShapes: true,
    roundAddButton: true,
    dotMarkers: true,
    floatingBar: true,
  );

  /// Every colour by token name (for the contrast test and the design notes).
  Map<String, Color> get tokens => {
    'background': background,
    'barFill': barFill,
    'barBorder': barBorder,
    'line': line,
    'heading': heading,
    'accent': accent,
    'accentAlt': accentAlt,
    'text': text,
    'textSecondary': textSecondary,
    'textDim': textDim,
    'cardFill': cardFill,
    'cardInk': cardInk,
    'cardMuted': cardMuted,
    'cardBorder': cardBorder,
    'cardBorderStrong': cardBorderStrong,
    'cardBorderActive': cardBorderActive,
    'cardDivider': cardDivider,
    'cardDisabled': cardDisabled,
    'controlBorder': controlBorder,
    'primaryFill': primaryFill,
    'onPrimary': onPrimary,
    'doneFill': doneFill,
    'onDone': onDone,
    'ring': ring,
  };

  /// The pairs a screen of this look must meet (data-model.md "Required pairs").
  List<LookPair> get requiredPairs => [
    (name: 'text/background', fg: text, bg: background, min: 4.5),
    (
      name: 'textSecondary/background',
      fg: textSecondary,
      bg: background,
      min: 4.5,
    ),
    (name: 'textDim/background', fg: textDim, bg: background, min: 4.5),
    (name: 'heading/background', fg: heading, bg: background, min: 3.0),
    (name: 'accent/background', fg: accent, bg: background, min: 4.5),
    (name: 'accentAlt/background', fg: accentAlt, bg: background, min: 3.0),
    (name: 'accentAlt/cardFill', fg: accentAlt, bg: cardFill, min: 3.0),
    (name: 'cardInk/cardFill', fg: cardInk, bg: cardFill, min: 4.5),
    (name: 'cardMuted/cardFill', fg: cardMuted, bg: cardFill, min: 4.5),
    (name: 'accent/cardFill', fg: accent, bg: cardFill, min: 4.5),
    (name: 'onPrimary/primaryFill', fg: onPrimary, bg: primaryFill, min: 4.5),
    (name: 'onDone/doneFill', fg: onDone, bg: doneFill, min: 4.5),
    (name: 'text/barFill', fg: text, bg: barFill, min: 4.5),
    (name: 'accent/barFill', fg: accent, bg: barFill, min: 4.5),
    (
      name: 'controlBorder/background',
      fg: controlBorder,
      bg: background,
      min: 3.0,
    ),
    (name: 'controlBorder/cardFill', fg: controlBorder, bg: cardFill, min: 3.0),
    (
      name: 'cardBorderActive/cardFill',
      fg: cardBorderActive,
      bg: cardFill,
      min: 3.0,
    ),
  ];

  /// Tokens that carry no information (hairlines, rings, disabled content) and so need no contrast.
  Set<String> get decorative => const {
    'barBorder',
    'line',
    'cardBorder',
    'cardBorderStrong',
    'cardDivider',
    'cardDisabled',
    'ring',
  };

  @override
  AppLook copyWith({
    Color? background,
    Color? barFill,
    Color? barBorder,
    Color? line,
    Color? heading,
    Color? accent,
    Color? accentAlt,
    Color? text,
    Color? textSecondary,
    Color? textDim,
    Color? cardFill,
    Color? cardInk,
    Color? cardMuted,
    Color? cardBorder,
    Color? cardBorderStrong,
    Color? cardBorderActive,
    Color? cardDivider,
    Color? cardDisabled,
    Color? controlBorder,
    Color? primaryFill,
    Color? onPrimary,
    Color? doneFill,
    Color? onDone,
    Color? ring,
    double? cardRadius,
    double? strongBorderWidth,
    bool? pillShapes,
    bool? roundAddButton,
    bool? dotMarkers,
    bool? floatingBar,
  }) => AppLook(
    background: background ?? this.background,
    barFill: barFill ?? this.barFill,
    barBorder: barBorder ?? this.barBorder,
    line: line ?? this.line,
    heading: heading ?? this.heading,
    accent: accent ?? this.accent,
    accentAlt: accentAlt ?? this.accentAlt,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    textDim: textDim ?? this.textDim,
    cardFill: cardFill ?? this.cardFill,
    cardInk: cardInk ?? this.cardInk,
    cardMuted: cardMuted ?? this.cardMuted,
    cardBorder: cardBorder ?? this.cardBorder,
    cardBorderStrong: cardBorderStrong ?? this.cardBorderStrong,
    cardBorderActive: cardBorderActive ?? this.cardBorderActive,
    cardDivider: cardDivider ?? this.cardDivider,
    cardDisabled: cardDisabled ?? this.cardDisabled,
    controlBorder: controlBorder ?? this.controlBorder,
    primaryFill: primaryFill ?? this.primaryFill,
    onPrimary: onPrimary ?? this.onPrimary,
    doneFill: doneFill ?? this.doneFill,
    onDone: onDone ?? this.onDone,
    ring: ring ?? this.ring,
    cardRadius: cardRadius ?? this.cardRadius,
    strongBorderWidth: strongBorderWidth ?? this.strongBorderWidth,
    pillShapes: pillShapes ?? this.pillShapes,
    roundAddButton: roundAddButton ?? this.roundAddButton,
    dotMarkers: dotMarkers ?? this.dotMarkers,
    floatingBar: floatingBar ?? this.floatingBar,
  );

  /// The theme is switched at once, never faded: halfway there is no look to draw, so this is [this] until the
  /// half and [other] after it.
  @override
  AppLook lerp(ThemeExtension<AppLook>? other, double t) =>
      other is AppLook && t >= 0.5 ? other : this;

  @override
  bool operator ==(Object other) =>
      other is AppLook &&
      _same(tokens.values, other.tokens.values) &&
      cardRadius == other.cardRadius &&
      strongBorderWidth == other.strongBorderWidth &&
      pillShapes == other.pillShapes &&
      roundAddButton == other.roundAddButton &&
      dotMarkers == other.dotMarkers &&
      floatingBar == other.floatingBar;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(tokens.values),
    cardRadius,
    strongBorderWidth,
    pillShapes,
    roundAddButton,
    dotMarkers,
    floatingBar,
  );

  static bool _same(Iterable<Color> a, Iterable<Color> b) {
    final x = a.toList();
    final y = b.toList();
    if (x.length != y.length) return false;
    for (var i = 0; i < x.length; i++) {
      if (x[i] != y[i]) return false;
    }
    return true;
  }
}

/// `context.look`: the look of the current [Theme], or Emerald & Gold when the theme has none (a plain
/// `MaterialApp`, as in tests that do not choose a look).
extension LookContext on BuildContext {
  AppLook get look => Theme.of(this).extension<AppLook>() ?? AppLook.emerald;
}

ThemeData buildAppTheme({AppLook look = AppLook.emerald}) {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: look.primaryFill,
    onPrimary: look.onPrimary,
    secondary: look.accentAlt,
    onSecondary: look.onPrimary,
    error: const Color(0xFFFFB4A9),
    onError: const Color(0xFF410002),
    surface: look.background,
    onSurface: look.text,
    surfaceContainerHighest: look.barFill,
    outline: look.controlBorder,
    outlineVariant: look.line,
    // The snack bar and the tooltip are drawn in the inverse colours, which are light by default; with dark cards
    // they are charcoal like the cards (Emerald & Gold keeps the defaults).
    inverseSurface: look.darkCards ? look.cardFill : null,
    onInverseSurface: look.darkCards ? look.cardInk : null,
  );
  final night = look.darkCards;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kUiFont,
    scaffoldBackgroundColor: look.background,
    extensions: <ThemeExtension<dynamic>>[look],
    appBarTheme: AppBarTheme(
      backgroundColor: look.background,
      foregroundColor: look.heading,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: kHeadingFont,
        fontWeight: FontWeight.w700,
        fontSize: 26,
        color: look.heading,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: look.accent,
      unselectedLabelColor: look.textSecondary,
      indicatorColor: look.accent,
      dividerColor: look.line,
    ),
    listTileTheme: ListTileThemeData(
      textColor: look.text,
      iconColor: look.accent,
    ),
    dividerTheme: DividerThemeData(color: look.line),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: look.controlBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: look.controlBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: look.accent, width: 2),
      ),
      labelStyle: TextStyle(color: look.textSecondary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: look.primaryFill,
        foregroundColor: look.onPrimary,
        minimumSize: const Size(64, 48),
        // A button's text style replaces the theme's, so it names the family itself (else the phone's font shows).
        textStyle: const TextStyle(
          fontFamily: kUiFont,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: look.accent),
    ),
    // Night Reader's transient surfaces: charcoal with a hairline, cards' radius. Emerald & Gold passes null for all
    // of these, so its theme is exactly as before.
    dialogTheme: night
        ? DialogThemeData(
            backgroundColor: look.cardFill,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(look.cardRadius),
              side: BorderSide(color: look.cardBorder),
            ),
          )
        : null,
    popupMenuTheme: night
        ? PopupMenuThemeData(
            color: look.cardFill,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: look.cardBorder),
            ),
          )
        : null,
    snackBarTheme: night
        ? SnackBarThemeData(
            backgroundColor: look.cardFill,
            contentTextStyle: TextStyle(
              fontFamily: kUiFont,
              color: look.cardInk,
              fontSize: 14,
            ),
            actionTextColor: look.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: look.controlBorder),
            ),
          )
        : null,
    tooltipTheme: night
        ? TooltipThemeData(
            decoration: BoxDecoration(
              color: look.cardFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: look.controlBorder),
            ),
            textStyle: TextStyle(
              fontFamily: kUiFont,
              color: look.cardInk,
              fontSize: 12,
            ),
          )
        : null,
    sliderTheme: night
        ? SliderThemeData(
            activeTrackColor: look.accent,
            inactiveTrackColor: look.line,
            thumbColor: look.accent,
            overlayColor: look.accent.withValues(alpha: 0.18),
          )
        : null,
  );
}
