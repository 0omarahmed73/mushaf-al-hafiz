// Feature 011, T054, a sweep (test-only): searching reads the bundled text and writes nothing (spec FR-017, FR-020,
// FR-021, SC-010; research D12). The source of `lib/search/` reaches no database, file, network, wird, backup or
// reminder code and none of the tafsir, translation or word-meaning code, and prints only inside `SearchTrace.emit`
// behind its flags; and through the real reader, index and search screen, typing twenty queries changes no row of any
// table, and a chosen surah and a chosen ayah change only the saved last viewed page.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/index_screen.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_trace.dart';

import '../support/reader_harness.dart' show settleReader;
import '../support/reader_search_harness.dart';
import '../support/search_harness.dart';

/// The files of `lib/search/`, by path.
Map<String, String> searchSources() => {
  for (final file
      in Directory('lib/search')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')))
    file.path: file.readAsStringSync(),
};

/// [source] without its comments (a `//` inside a string is not expected in these files; a URL would be a finding).
String codeOf(String source) => source
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .split('\n')
    .map((line) {
      final at = line.indexOf('//');
      return at < 0 ? line : line.substring(0, at);
    })
    .join('\n');

/// The URIs a file imports, exports or takes as a part.
List<String> urisOf(String source) => [
  for (final m in RegExp(
    r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  ).allMatches(codeOf(source)))
    m.group(1)!,
];

/// The path under `lib/` a relative or `package:mushaf/` URI of a file of `lib/search/` points to; null for another
/// package or a `dart:` library.
String? libPathOf(String uri) {
  if (uri.startsWith('package:mushaf/')) {
    return uri.substring('package:mushaf/'.length);
  }
  if (uri.contains(':')) return null;
  return Uri.parse('search/').resolve(uri).path;
}

/// Every row of every table of [db], by table name.
Future<Map<String, List<String>>> dump(WidgetTester t, SearchReader r) async {
  return (await t.runAsync(() async {
    final tables = await r.db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    final out = <String, List<String>>{};
    for (final table in tables) {
      final name = table.data['name'] as String;
      final rows = await r.db
          .customSelect('SELECT * FROM "$name" ORDER BY rowid')
          .get();
      out[name] = [for (final row in rows) row.data.toString()];
    }
    return out;
  }))!;
}

Future<void> openSearchFromReader(WidgetTester t) async {
  await t.tap(keyed('open-index'));
  await settleReader(t);
  await t.tap(keyed('open-search'));
  await settleReader(t);
  expect(find.byType(SearchScreen), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the source of lib/search/', () {
    late Map<String, String> sources;
    setUpAll(() => sources = searchSources());

    test('is the files this sweep expects to read', () {
      expect(
        sources.keys,
        containsAll([
          'lib/search/arabic_fold.dart',
          'lib/search/ayah_index.dart',
          'lib/search/ayah_target.dart',
          'lib/search/search_rows.dart',
          'lib/search/search_screen.dart',
          'lib/search/search_service.dart',
          'lib/search/search_session.dart',
          'lib/search/search_strings.dart',
          'lib/search/search_trace.dart',
          'lib/search/snippet.dart',
          'lib/search/surah_search.dart',
        ]),
      );
      // the helpers of this sweep see what they must
      expect(
        urisOf(
          "import 'dart:io';\n// import 'x.dart';\nexport \"a/b.dart\" show C;",
        ),
        ['dart:io', 'a/b.dart'],
      );
      expect(libPathOf('../wirds/db.dart'), 'wirds/db.dart');
      expect(libPathOf('search_strings.dart'), 'search/search_strings.dart');
      expect(
        libPathOf('package:mushaf/backup/backup.dart'),
        'backup/backup.dart',
      );
      expect(libPathOf('package:provider/provider.dart'), isNull);
    });

    test('imports no package but flutter, material_ui and provider, and no dart:io', () {
      const packages = {'flutter', 'material_ui', 'provider', 'mushaf'};
      const dartLibraries = {
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:core',
        'dart:math',
        'dart:typed_data',
        'dart:ui',
      };
      for (final entry in sources.entries) {
        for (final uri in urisOf(entry.value)) {
          if (uri.startsWith('dart:')) {
            expect(
              dartLibraries,
              contains(uri),
              reason: '${entry.key} imports $uri',
            );
          } else if (uri.startsWith('package:')) {
            final package = uri.substring('package:'.length).split('/').first;
            expect(
              packages,
              contains(package),
              reason: '${entry.key} imports $uri',
            );
          }
        }
      }
    });

    test('imports nothing of the wirds, the backup, the reminders, the database or the settings store', () {
      const forbidden = [
        'wirds/',
        'backup/',
        'reminders/',
        'kahf/',
        'khatm/',
        'pdf/',
      ];
      for (final entry in sources.entries) {
        for (final uri in urisOf(entry.value)) {
          final path = libPathOf(uri);
          if (path == null) continue;
          expect(
            path,
            isNot(startsWith('../')),
            reason: '${entry.key} imports $uri (outside lib/)',
          );
          for (final dir in forbidden) {
            expect(
              path,
              isNot(startsWith(dir)),
              reason: '${entry.key} imports $uri',
            );
          }
          expect(
            File('lib/$path').existsSync(),
            isTrue,
            reason: '${entry.key} imports $uri',
          );
        }
      }
    });

    test('imports nothing of the tafsir, the translation or the word meanings (FR-020)', () {
      const allowedOfAyah = {'ayah/ayah_ref.dart', 'ayah/ui/reading_text.dart'};
      for (final entry in sources.entries) {
        for (final uri in urisOf(entry.value)) {
          final path = libPathOf(uri);
          if (path == null || !path.startsWith('ayah/')) continue;
          expect(
            allowedOfAyah,
            contains(path),
            reason: '${entry.key} imports $uri',
          );
        }
        final code = codeOf(entry.value);
        for (final name in [
          'AyahRepository',
          'TafsirView',
          'TranslationView',
          'MeaningsView',
          'ShareTextBuilder',
        ]) {
          expect(
            code,
            isNot(contains(name)),
            reason: '${entry.key} names $name',
          );
        }
      }
    });

    test('opens no file, directory or connection, and keeps nothing', () {
      final reaching = RegExp(
        r'\bFile\s*\(|\bDirectory\s*\(|\bHttpClient\b|\bSocket\b|\bWebSocket\b|\bRandomAccessFile\b|\bProcess\b|'
        r'\bSharedPreferences\b|getApplicationDocumentsDirectory|getTemporaryDirectory|\bClipboard\b|'
        r'\bMethodChannel\b|https?://|\bcustomSelect\b|\bAppDatabase\b|\bWirdRepository\b',
      );
      for (final entry in sources.entries) {
        final lines = codeOf(entry.value).split('\n');
        for (var i = 0; i < lines.length; i++) {
          expect(
            reaching.hasMatch(lines[i]),
            isFalse,
            reason: '${entry.key}:${i + 1}: ${lines[i].trim()}',
          );
        }
      }
    });

    test('prints only inside SearchTrace.emit, behind the SEARCH_TRACE / SEARCH_BENCH flags', () {
      final printing = RegExp(
        r'\b(print|debugPrint|debugPrintSynchronously|debugPrintThrottled|log|stdout|stderr)\b\s*[(.]',
      );
      final found = <String>[];
      for (final entry in sources.entries) {
        final lines = codeOf(entry.value).split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (printing.hasMatch(lines[i])) {
            found.add('${entry.key}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      expect(found, hasLength(1), reason: 'one place prints: $found');
      expect(found.single, startsWith('lib/search/search_trace.dart:'));

      // that place is the body of `emit`, and the first thing `emit` does is leave when both flags are off
      final trace = codeOf(sources['lib/search/search_trace.dart']!);
      final emit = RegExp(
        r'static\s+void\s+emit\s*\(\s*String\s+\w+\s*\)\s*\{(.*?)\n  \}',
        dotAll: true,
      ).firstMatch(trace);
      expect(emit, isNotNull, reason: 'SearchTrace.emit(String) exists');
      final body = emit!.group(1)!.trim();
      expect(
        body,
        matches(RegExp(r'^if\s*\(\s*!enabled\s*&&\s*!bench\s*\)\s*return;')),
        reason: 'the guard comes first: $body',
      );
      expect(
        printing.allMatches(body),
        hasLength(1),
        reason: 'the print is inside emit',
      );
      expect(
        trace,
        contains(
          RegExp(
            r"static const bool enabled\s*=\s*bool\.fromEnvironment\('SEARCH_TRACE'\);",
          ),
        ),
      );
      expect(
        trace,
        contains(
          RegExp(
            r"static const bool bench\s*=\s*bool\.fromEnvironment\('SEARCH_BENCH'\);",
          ),
        ),
      );
      expect(SearchTrace.enabled, isFalse);
      expect(SearchTrace.bench, isFalse);
    });

    test('hands a line to SearchTrace.emit only behind a flag, and a line never holds the typed text', () {
      for (final entry in sources.entries) {
        if (entry.key.endsWith('search_trace.dart')) continue;
        final code = codeOf(entry.value);
        for (final m in RegExp(r'SearchTrace\.emit').allMatches(code)) {
          // the statement the mention is in (back to the previous `;`, `{` or `}`)
          final from = code.lastIndexOf(RegExp(r'[;{}]'), m.start) + 1;
          final statement = code.substring(from, m.end);
          expect(
            statement,
            contains(RegExp(r'SearchTrace\.(enabled|bench)')),
            reason:
                '${entry.key}: «${statement.trim()}» is not behind SearchTrace.enabled / SearchTrace.bench',
          );
        }
      }
      // the three lines take numbers only
      expect(SearchTrace.queryLine(6, 48, 5), matches(RegExp(r'^[ -~]+$')));
      expect(SearchTrace.prepareLine(1200, 140), matches(RegExp(r'^[ -~]+$')));
      expect(SearchTrace.benchLine(3, 1746, 7), matches(RegExp(r'^[ -~]+$')));
    });
  });

  group('through the reader, the index and the search screen', () {
    setUpAll(() async {
      await preloadReaderPages();
      await realIndex();
    });

    testWidgets('twenty queries change no row of any table and print nothing', (
      t,
    ) async {
      final printed = <String>[];
      final before = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          printed.add('$message');
      addTearDown(() => debugPrint = before);

      final reader = await pumpSearchReader(t, startPage: 50);
      final rows = await dump(t, reader);
      expect(
        rows.keys,
        containsAll(['bookmarks', 'settings', 'wird_days', 'wirds']),
      );
      expect(rows['settings'], isNotEmpty);

      await openSearchFromReader(t);
      expect(SearchTrace.benchQueries, hasLength(20));
      for (final query in SearchTrace.benchQueries) {
        await typeQuery(t, query);
      }
      expect(
        await dump(t, reader),
        rows,
        reason: 'after typing the twenty queries',
      );

      // leaving without a choice
      await t.binding.handlePopRoute();
      await settleReader(t);
      await t.binding.handlePopRoute();
      await settleReader(t);
      expect(find.byType(ReaderScreen), findsOneWidget);
      expect(find.byType(IndexScreen), findsNothing);
      expect(await dump(t, reader), rows, reason: 'after leaving the search');
      expect(printed.where((line) => line.contains('SEARCH')), isEmpty);
      for (final query in SearchTrace.benchQueries) {
        expect(printed.where((line) => line.contains(query)), isEmpty);
      }
    });

    testWidgets(
      'a chosen surah and a chosen ayah change only the saved last viewed page',
      (t) async {
        final reader = await pumpSearchReader(t, startPage: 50);
        final rows = await dump(t, reader);
        final lastBefore = await t.runAsync(reader.repo.lastViewedPage);

        /// The rows that are not as they were at the start, as `table: row`.
        Future<List<String>> changed() async {
          final now = await dump(t, reader);
          expect(now.keys, rows.keys);
          return [
            for (final table in now.keys) ...[
              for (final row in now[table]!)
                if (!rows[table]!.contains(row)) '$table: $row',
              for (final row in rows[table]!)
                if (!now[table]!.contains(row)) '$table (gone): $row',
            ],
          ];
        }

        // a surah result: surah 18, whose first page is 293
        await openSearchFromReader(t);
        for (final query in SearchTrace.benchQueries.take(10)) {
          await typeQuery(t, query);
        }
        await typeQuery(t, 'الكهف');
        await t.tap(keyed('surah-row-18'));
        await settleReader(t);
        expect(find.byType(SearchScreen), findsNothing);
        expect(find.byType(IndexScreen), findsNothing);
        expect(shownPage(t), '293');
        expect(await t.runAsync(reader.repo.lastViewedPage), 293);
        expect(lastBefore, isNot(293));
        var differences = await changed();
        expect(
          differences.where((d) => !d.startsWith('settings')),
          isEmpty,
          reason: 'only the settings table may differ: $differences',
        );
        final settingsChanged = differences
            .where((d) => !d.contains('(gone)'))
            .toList();
        expect(
          settingsChanged,
          hasLength(1),
          reason: 'one row: the last viewed page; $differences',
        );
        expect(settingsChanged.single, contains('293'));
        final lastPageRow = settingsChanged.single.replaceAll('293', '<page>');

        // an ayah result: 18:60, on page 300
        await openSearchFromReader(t);
        for (final query in SearchTrace.benchQueries.skip(10)) {
          await typeQuery(t, query);
        }
        await typeQuery(t, 'مجمع البحرين');
        await t.tap(keyed('ayah-row-18:60'));
        await settleReader(t);
        expect(find.byType(SearchScreen), findsNothing);
        expect(shownPage(t), '300');
        expect(await t.runAsync(reader.repo.lastViewedPage), 300);
        differences = await changed();
        expect(
          differences.where((d) => !d.startsWith('settings')),
          isEmpty,
          reason: 'only the settings table may differ: $differences',
        );
        final afterAyah = differences
            .where((d) => !d.contains('(gone)'))
            .toList();
        expect(afterAyah, hasLength(1), reason: 'still one row: $differences');
        expect(
          afterAyah.single.replaceAll('300', '<page>'),
          lastPageRow,
          reason: 'the same row, now 300',
        );
        // no table gained or lost a row, but for the one row of the last viewed page when it was not yet saved
        final now = await dump(t, reader);
        for (final table in rows.keys) {
          final gained = now[table]!.length - rows[table]!.length;
          expect(gained, table == 'settings' ? anyOf(0, 1) : 0, reason: table);
        }
      },
    );
  });
}
