// Ayah-end markers derived from the page data (spec FR-007; data-model.md PageData.endMarkerIds; research D3): a word
// is a marker when the next word in Mushaf order belongs to another ayah, the last word of a page deciding with the
// first word of the next page. Over the real 604 pages there are exactly 6,236, one per ayah, each the last word of its
// ayah, and loading never fails because a next page is missing.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

import '../support/map_bundle.dart';

/// A page file with one ayah line of [words] (id, key).
String pageJson(int page, List<(int, String)> words) => jsonEncode({
  'page': page,
  'juz': 1,
  'hizbQuarter': 1,
  'lines': [
    {
      'n': 1,
      'type': 'ayah',
      'centered': false,
      'surah': null,
      'words': [
        for (final (id, key) in words) {'id': id, 'k': key, 'g': 'x'},
      ],
    },
  ],
});

List<MushafWord> wordsOf(PageData p) => [for (final l in p.lines) ...l.words];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PageData has no markers until it is told which words are one', () {
    final p = PageData(page: 1, juz: 1, hizbQuarter: 1, lines: const []);
    expect(p.endMarkerIds, isEmpty);
  });

  group('over the real pages', () {
    test(
      'exactly 6,236 markers, one per ayah, each the last word of its ayah',
      () async {
        final repo = MushafRepository(rootBundle);
        final markers = <MushafWord>[];
        final all = <MushafWord>[];
        for (var page = 1; page <= MushafMeta.pageCount; page++) {
          final data = await repo.loadPage(page);
          final words = wordsOf(data);
          all.addAll(words);
          for (final id in data.endMarkerIds) {
            markers.add(words.firstWhere((w) => w.id == id));
          }
          final onPage = {for (final w in words) w.id};
          expect(
            data.endMarkerIds.every(onPage.contains),
            isTrue,
            reason: 'page $page marks only its own words',
          );
        }
        expect(all.length, 83668);
        expect(markers.length, 6236);
        // One per ayah.
        final byAyah = <String, List<MushafWord>>{};
        for (final m in markers) {
          byAyah.putIfAbsent('${m.surah}:${m.ayah}', () => []).add(m);
        }
        expect(byAyah.length, 6236, reason: 'every ayah has a marker');
        expect(byAyah.values.every((l) => l.length == 1), isTrue);
        // Each is the last word of its ayah, and no other word is a marker.
        final lastOfAyah = <String, MushafWord>{};
        for (final w in all) {
          lastOfAyah['${w.surah}:${w.ayah}'] = w;
        }
        for (final e in lastOfAyah.entries) {
          expect(byAyah[e.key]!.single.id, e.value.id, reason: e.key);
        }
      },
    );

    test(
      'the markers do not depend on the order the pages are loaded in',
      () async {
        final forward = MushafRepository(rootBundle);
        final backward = MushafRepository(rootBundle);
        final a = <int, Set<int>>{};
        for (final page in [1, 2, 3, 77, 293, 603, 604]) {
          a[page] = (await forward.loadPage(page)).endMarkerIds;
        }
        for (final page in [604, 603, 293, 77, 3, 2, 1]) {
          expect(
            (await backward.loadPage(page)).endMarkerIds,
            a[page],
            reason: 'page $page',
          );
        }
      },
    );

    test('page 1: the last word of each of the seven ayahs, page 604: the last word of the page', () async {
      final repo = MushafRepository(rootBundle);
      final p1 = await repo.loadPage(1);
      expect(p1.endMarkerIds.length, 7);
      final p604 = await repo.loadPage(604);
      expect(p604.endMarkerIds, contains(wordsOf(p604).last.id));
    });
  });

  group('best effort when the next page is not there', () {
    test('a page whose next page is missing loads with no exception; its last word is not a marker', () async {
      final repo = MushafRepository(
        MapBundle({
          'assets/mushaf/pages/p001.json': pageJson(1, [
            (1, '1:1:1'),
            (2, '1:1:2'),
            (3, '1:2:1'),
          ]),
        }),
      );
      final p = await repo.loadPage(1);
      expect(p.endMarkerIds, {2}, reason: '1:1:2 ends 1:1; 1:2:1 may go on');
    });

    test(
      'a bundle that fails on the next page does not fail this page',
      () async {
        final repo = MushafRepository(
          MapBundle({
            'assets/mushaf/pages/p001.json': pageJson(1, [(1, '1:1:1')]),
            'assets/mushaf/pages/p002.json': 'not json at all',
          }),
        );
        final p = await repo.loadPage(1);
        expect(p.endMarkerIds, isEmpty);
      },
    );

    test(
      'the last word of page 604 is a marker even with no next page',
      () async {
        final repo = MushafRepository(
          MapBundle({
            'assets/mushaf/pages/p604.json': pageJson(604, [(1, '114:6:1')]),
          }),
        );
        expect((await repo.loadPage(604)).endMarkerIds, {1});
      },
    );

    test('the next page decides the last word of this one, and asking costs one extra read at most', () async {
      final bundle = MapBundle({
        'assets/mushaf/pages/p001.json': pageJson(1, [
          (1, '1:1:1'),
          (2, '1:1:2'),
        ]),
        'assets/mushaf/pages/p002.json': pageJson(2, [
          (3, '1:1:3'),
          (4, '1:2:1'),
        ]),
      });
      final repo = MushafRepository(bundle);
      final p1 = await repo.loadPage(1);
      expect(
        p1.endMarkerIds,
        isEmpty,
        reason: '1:1:2 goes on with 1:1:3 on the next page',
      );
      final p2 = await repo.loadPage(2);
      expect(p2.endMarkerIds, {
        3,
      }, reason: '1:1:3 ends 1:1; 1:2:1 is last and page 3 is missing');
      expect(bundle.loads.where((k) => k.endsWith('p001.json')).length, 1);
      // Loading page 1 read page 2's file once for its first word; loading page 2 read it again for the page.
      expect(
        bundle.loads.where((k) => k.endsWith('p002.json')).length,
        lessThanOrEqualTo(2),
      );
    });
  });
}
