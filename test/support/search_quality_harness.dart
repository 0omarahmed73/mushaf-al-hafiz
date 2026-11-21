// Helpers of the behaviour and quality tests of the search screen (feature 011, T050-T057), over `search_harness.dart`:
// finders by the contract's keys, the stand-in services, the checks of colour, contrast and size. Nothing here knows how
// the screen is built: only the keys, the strings and the tokens of contracts/ui.md and contracts/dart-interfaces.md.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart' show kQuranFont;
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';

import 'search_harness.dart';

// ---------------------------------------------------------------------------------------------------------------------
// Finders (contracts/dart-interfaces.md "Keys for tests")
// ---------------------------------------------------------------------------------------------------------------------

Finder skey(String k) => find.byKey(ValueKey(k));

Finder get searchField => skey('search-field');
Finder get searchClear => skey('search-clear');
Finder get searchRetry => skey('search-retry');
Finder get searchMoreLine => skey('search-more-line');
Finder get surahsHeading => skey('search-heading-surahs');
Finder get ayatHeading => skey('search-heading-ayat');
Finder surahRow(int surah) => skey('surah-row-$surah');
Finder ayahRow(int surah, int ayah) => skey('ayah-row-$surah:$ayah');

/// The list under the field: the one vertical scrollable of the screen (the field's own scrollable is horizontal).
Finder get searchList => find.descendant(
  of: find.byType(SearchScreen),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Scrollable &&
        axisDirectionToAxis(w.axisDirection) == Axis.vertical,
  ),
);

ScrollPosition searchPosition(WidgetTester t) =>
    t.state<ScrollableState>(searchList).position;

List<String> _keysStarting(WidgetTester t, String prefix) => [
  for (final w in t.widgetList(
    find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> && k.value.startsWith(prefix);
    }),
  ))
    (w.key! as ValueKey<String>).value.substring(prefix.length),
];

/// The ayah rows now built, as `surah:ayah`, in the order of the list.
List<String> ayahRowsBuilt(WidgetTester t) => _keysStarting(t, 'ayah-row-');

/// The surah rows now built, as their numbers, in the order of the list.
List<int> surahRowsBuilt(WidgetTester t) => [
  for (final k in _keysStarting(t, 'surah-row-')) int.parse(k),
];

/// The text of the field as it stands.
String fieldText(WidgetTester t) =>
    t.widget<TextField>(searchField).controller!.text;

/// The snippet of an ayah row: its one text in the Quran font (contracts/ui.md "Rows").
Finder snippetIn(Finder row) => find.descendant(
  of: row,
  matching: find.byWidgetPredicate(
    (w) => w is RichText && _hasQuranFont(w.text, null),
  ),
);

bool _hasQuranFont(InlineSpan span, TextStyle? inherited) {
  if (span is! TextSpan) return false;
  final style = inherited?.merge(span.style) ?? span.style;
  if ((span.text ?? '').trim().isNotEmpty && style?.fontFamily == kQuranFont) {
    return true;
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (_hasQuranFont(child, style)) return true;
  }
  return false;
}

/// One run of a text with the style it is drawn in (its own merged over its parents').
class StyledRun {
  const StyledRun(this.text, this.style);
  final String text;
  final TextStyle style;
}

/// The runs of [rich] that hold something to read, in order.
List<StyledRun> runsOf(RichText rich) {
  final runs = <StyledRun>[];
  void walk(InlineSpan span, TextStyle? inherited) {
    if (span is! TextSpan) return;
    final style = inherited?.merge(span.style) ?? span.style;
    final text = span.text ?? '';
    if (text.trim().isNotEmpty) {
      runs.add(StyledRun(text, style ?? const TextStyle()));
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      walk(child, style);
    }
  }

  walk(rich.text, null);
  return runs;
}

/// The font size [rich] is drawn at: the style's size through the text scaler in use.
double drawnSize(RichText rich, TextStyle style) =>
    rich.textScaler.scale(style.fontSize ?? 14);

// ---------------------------------------------------------------------------------------------------------------------
// Opening and leaving
// ---------------------------------------------------------------------------------------------------------------------

/// Opens the search screen once more over the same app (after an earlier one was closed).
Future<void> reopenSearch(WidgetTester t, SearchRun run) async {
  unawaited(
    run.navigator.currentState!.push<Object>(
      MaterialPageRoute<Object>(builder: (_) => const SearchScreen()),
    ),
  );
  await settleSearch(t);
}

/// The system back, until the route is gone.
Future<void> closeSearch(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await settleSearch(t);
}

// ---------------------------------------------------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------------------------------------------------

/// The real answers to [typed], keyed by the folded query, from a prepared service over the real index (call from
/// `setUpAll`).
Future<Map<String, AyahSearchResult>> realAnswers(
  Iterable<String> typed,
) async {
  final service = SearchService.prepared(
    await realIndex(),
    await realMeta(),
    yieldTurn: () async {},
  );
  final answers = <String, AyahSearchResult>{};
  for (final text in typed) {
    final folded = ArabicFold.query(text);
    answers[folded] = (await service.searchAyat(
      folded,
      isCurrent: () => true,
    ))!;
  }
  service.dispose();
  return answers;
}

/// A hit on [ref] made of the ayah's real words, the first one marked as matched.
AyahHit hitOf(AyahIndex index, MushafMeta meta, AyahRef ref) {
  final words = index.storedWords(index.indexOf(ref));
  return AyahHit(
    ref: ref,
    page: meta.pageOfAyah(ref.surah, ref.ayah),
    words: words,
    matched: [for (var i = 0; i < words.length; i++) i == 0],
  );
}

/// A ready service whose answers wait until the test hands them out, in any order, and which hands a late answer over
/// even when it is no longer wanted (the screen must drop it by itself).
class GatedSearchService extends ChangeNotifier implements SearchService {
  /// Every folded query asked, in order.
  final List<String> asked = [];
  final Map<String, List<Completer<AyahSearchResult?>>> _waiting = {};
  int prepareCalls = 0;
  int retryCalls = 0;

  /// How many listeners the service has now (the screen's session, and the provider above the app once it was read).
  int listeners = 0;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }

  @override
  IndexPhase get phase => IndexPhase.ready;

  @override
  Object? get failure => null;

  @override
  Future<void> prepare() async => prepareCalls++;

  @override
  Future<void> retry() async => retryCalls++;

  @override
  Future<AyahSearchResult?> searchAyat(
    String foldedQuery, {
    required bool Function() isCurrent,
  }) {
    asked.add(foldedQuery);
    final answer = Completer<AyahSearchResult?>();
    (_waiting[foldedQuery] ??= []).add(answer);
    return answer.future;
  }

  /// Whether a question about [typed] is still unanswered.
  bool waits(String typed) =>
      (_waiting[ArabicFold.query(typed)] ?? const []).isNotEmpty;

  /// Answers every waiting question about [typed] with [result].
  void answer(String typed, AyahSearchResult result) {
    final waiting = _waiting.remove(ArabicFold.query(typed)) ?? const [];
    for (final one in waiting) {
      one.complete(result);
    }
  }
}

/// The 114 text files behind a gate: a load is counted when asked and answered only once [open] was called.
class GatedTextBundle extends CachingAssetBundle {
  GatedTextBundle(this.files);

  final Map<String, String> files;
  final Map<String, int> loads = {};
  final Completer<void> _gate = Completer<void>();

  void open() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    loads[key] = (loads[key] ?? 0) + 1;
    await _gate.future;
    return files[key]!;
  }

  @override
  Future<ByteData> load(String key) =>
      throw StateError('only loadString is expected: $key');
}

// ---------------------------------------------------------------------------------------------------------------------
// What a screen reader is told
// ---------------------------------------------------------------------------------------------------------------------

/// Records every announcement sent to the platform (`SemanticsService.sendAnnouncement`) until the test ends.
List<String> recordAnnouncements(WidgetTester t) {
  final sent = <String>[];
  t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
    SystemChannels.accessibility,
    (message) async {
      final map = message as Map;
      if (map['type'] == 'announce') {
        sent.add((map['data'] as Map)['message'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () =>
        t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return sent;
}

// ---------------------------------------------------------------------------------------------------------------------
// Errors, colours, contrast
// ---------------------------------------------------------------------------------------------------------------------

/// Collects every framework error (an overflow is one) from now until the test ends, instead of stopping at the first.
List<FlutterErrorDetails> collectErrors() {
  final errors = <FlutterErrorDetails>[];
  final before = FlutterError.onError;
  FlutterError.onError = (details) {
    // what the framework reports about the screen (an overflow, a build error) is collected; a failed expectation or
    // an error of the test's own code is the test's verdict and goes where it always goes
    if (details.exception is FlutterError) {
      errors.add(details);
    } else {
      before?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = before);
  return errors;
}

String describeErrors(List<FlutterErrorDetails> errors) =>
    errors.map((e) => e.exceptionAsString().split('\n').first).join('\n');

bool _red(Color c) {
  if (c.a < 0.2) return false;
  final hsv = HSVColor.fromColor(c);
  return (hsv.hue >= 340 || hsv.hue <= 20) &&
      hsv.saturation >= 0.45 &&
      hsv.value >= 0.35;
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Everything of the search screen that is drawn in red or in the theme's error colour: a text, an icon, a fill, an
/// error text of the field (contracts/ui.md "States": no error, no red).
List<String> redThings(WidgetTester t) {
  final found = <String>[];
  final screen = find.byType(SearchScreen);
  final error = Theme.of(t.element(screen)).colorScheme.error;
  void check(String what, Color? c) {
    if (c == null) return;
    if (_red(c) || (c.a > 0.2 && c.toARGB32() == error.toARGB32())) {
      found.add('$what ${_hex(c)}');
    }
  }

  Finder inside(Type type) =>
      find.descendant(of: screen, matching: find.byType(type));
  for (final rich in t.widgetList<RichText>(inside(RichText))) {
    for (final run in runsOf(rich)) {
      check('text "${run.text}"', run.style.color);
      check('underline of "${run.text}"', run.style.decorationColor);
    }
  }
  for (final e in inside(Icon).evaluate()) {
    final icon = e.widget as Icon;
    check('icon', icon.color ?? IconTheme.of(e).color);
  }
  for (final m in t.widgetList<Material>(inside(Material))) {
    check('Material', m.color);
  }
  for (final b in t.widgetList<ColoredBox>(inside(ColoredBox))) {
    check('ColoredBox', b.color);
  }
  for (final d in t.widgetList<DecoratedBox>(inside(DecoratedBox))) {
    final decoration = d.decoration;
    if (decoration is BoxDecoration) check('DecoratedBox', decoration.color);
  }
  final decoration = t.widget<TextField>(searchField).decoration;
  if (decoration?.errorText != null || decoration?.error != null) {
    found.add('the field shows an error text');
  }
  return found;
}

/// The painted fills that are bright (an ivory card, a light bar) among the widgets now on screen (the same rule as
/// `test/look/theme_only_screens_night_test.dart`).
List<String> brightFillsOnScreen(WidgetTester t) {
  final found = <String>[];
  for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final decoration = d.decoration;
    final c = decoration is BoxDecoration ? decoration.color : null;
    if (c != null && c.a > 0.5 && c.computeLuminance() > 0.5) {
      found.add('DecoratedBox ${_hex(c)}');
    }
  }
  for (final m in t.widgetList<Material>(find.byType(Material))) {
    final c = m.color;
    if (c != null && c.a > 0.5 && c.computeLuminance() > 0.5) {
      found.add('Material ${_hex(c)}');
    }
  }
  for (final b in t.widgetList<ColoredBox>(find.byType(ColoredBox))) {
    final c = b.color;
    if (c.a > 0.5 && c.computeLuminance() > 0.5) {
      found.add('ColoredBox ${_hex(c)}');
    }
  }
  return found;
}

/// Every run of text of the search screen, a run inside a `Text.rich` included (the matched words, «…»), whose colour
/// has less than [minimum] contrast against the colour painted behind it. Text under a reduced opacity is exempt.
List<String> runContrastIssues(WidgetTester t, {double minimum = 4.5}) {
  final issues = <String>[];
  final texts = find.descendant(
    of: find.byType(SearchScreen),
    matching: find.byType(RichText),
  );
  for (final element in texts.evaluate()) {
    if (_faded(element) || _insideIcon(element)) continue;
    final bg = _backgroundBehind(element);
    for (final run in runsOf(element.widget as RichText)) {
      final fg = run.style.color;
      if (fg == null) continue;
      final solid = fg.a < 1 ? Color.alphaBlend(fg, bg) : fg;
      final ratio = contrastRatio(solid, bg);
      if (ratio < minimum) {
        issues.add(
          'text "${run.text}" ${_hex(solid)} on ${_hex(bg)} = ${ratio.toStringAsFixed(2)} (needs $minimum)',
        );
      }
    }
  }
  return issues;
}

bool _faded(Element element) {
  var faded = false;
  element.visitAncestorElements((a) {
    final w = a.widget;
    if ((w is Opacity && w.opacity < 1) ||
        (w is AnimatedOpacity && w.opacity < 1)) {
      faded = true;
      return false;
    }
    return true;
  });
  return faded;
}

bool _insideIcon(Element element) {
  var inside = false;
  element.visitAncestorElements((a) {
    if (a.widget is Icon) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

Color _backgroundBehind(Element element) {
  final layers = <Color>[];
  Color? base;
  element.visitAncestorElements((a) {
    final w = a.widget;
    Color? c;
    if (w is ColoredBox) {
      c = w.color;
    } else if (w is DecoratedBox) {
      final d = w.decoration;
      if (d is BoxDecoration) c = d.color;
    } else if (w is Material) {
      if (w.type != MaterialType.transparency) {
        c = w.color ?? Theme.of(a).canvasColor;
      }
    } else if (w is Scaffold) {
      c = w.backgroundColor ?? Theme.of(a).scaffoldBackgroundColor;
    }
    if (c != null && c.a > 0) {
      if (c.a >= 1) {
        base = c;
        return false;
      }
      layers.add(c);
    }
    return true;
  });
  var result = base ?? const Color(0xFF000000);
  for (final layer in layers.reversed) {
    result = Color.alphaBlend(layer, result);
  }
  return result;
}
