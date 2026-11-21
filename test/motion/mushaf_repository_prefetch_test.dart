// Feature 010 T005: peek and prefetch of the repository, and one read of each page file (research D4, H5).
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

import '../support/motion_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'peek is null until the page is loaded, then the page, and reads nothing',
    () async {
      final bundle = FileBundle();
      final repo = MushafRepository(bundle);
      expect(repo.peek(50), isNull);
      final page = await repo.loadPage(50);
      bundle.loads.clear();
      expect(repo.peek(50), same(page));
      expect(bundle.loads, isEmpty);
      expect(repo.peek(0), isNull);
      expect(repo.peek(605), isNull);
    },
  );

  test('prefetch loads a page for later, ignores a page that cannot be read and one outside 1..604', () async {
    final bundle = FileBundle();
    final repo = MushafRepository(bundle);
    await repo.prefetch(70);
    expect(repo.peek(70), isNotNull);
    await repo.prefetch(0);
    await repo.prefetch(605);
    final broken = MushafRepository(_Missing());
    await broken.prefetch(3);
    expect(broken.peek(3), isNull);
  });

  test('prefetching 20 pages in a row reads every page file once (it read each twice before)', () async {
    final bundle = FileBundle();
    final repo = MushafRepository(bundle);
    for (var p = 100; p < 120; p++) {
      await repo.prefetch(p);
    }
    final pageFiles = bundle.loads.where((k) => k.contains('/pages/')).toList();
    expect(
      pageFiles.toSet().length,
      pageFiles.length,
      reason: 'no page file is read twice',
    );
    expect(
      pageFiles.length,
      21,
      reason: '20 pages and the first word of the page after the last one',
    );
  });

  test(
    'descending and a page asked on its own read each file once too',
    () async {
      final bundle = FileBundle();
      final repo = MushafRepository(bundle);
      for (var p = 219; p >= 200; p--) {
        await repo.loadPage(p);
      }
      final files = bundle.loads.where((k) => k.contains('/pages/')).toList();
      expect(files.toSet().length, files.length);
    },
  );

  test('two askers of the same page share one read', () async {
    final bundle = FileBundle();
    final repo = MushafRepository(bundle);
    final a = repo.loadPage(321);
    final b = repo.prefetch(321);
    await Future.wait([a, b]);
    expect(bundle.loads.where((k) => k.endsWith('p321.json')).length, 1);
  });

  test('the end markers of all 604 pages are the same whatever the order they are loaded in (6,236 in all)', () async {
    Future<Set<int>> markers(
      Iterable<int> order, {
      bool prefetch = false,
    }) async {
      final repo = MushafRepository(FileBundle());
      final ids = <int>{};
      for (final p in order) {
        if (prefetch) await repo.prefetch(p);
        ids.addAll((await repo.loadPage(p)).endMarkerIds);
      }
      return ids;
    }

    final ascending = await markers([
      for (var p = 1; p <= 604; p++) p,
    ], prefetch: true);
    final descending = await markers([for (var p = 604; p >= 1; p--) p]);
    final alone = <int>{};
    for (var p = 1; p <= 604; p += 3) {
      alone.addAll(
        (await MushafRepository(FileBundle()).loadPage(p)).endMarkerIds,
      );
    }
    expect(ascending.length, 6236);
    expect(descending, ascending);
    expect(
      ascending.containsAll(alone),
      isTrue,
      reason: 'a page loaded alone marks the same words',
    );
  });
}

class _Missing extends FileBundle {
  @override
  Future<ByteData> load(String key) => throw StateError('missing');
}
