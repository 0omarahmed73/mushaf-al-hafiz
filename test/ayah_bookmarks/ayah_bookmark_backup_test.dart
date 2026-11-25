// The backup file and ayah bookmarks (feature 013, spec FR-014, SC-004; data-model.md Backup file; research D3): version 2
// only when an ayah bookmark exists, version 1 still read completely, ayah bookmarks checked against the real Mushaf (the
// meta of the fixed edition through MushafRepository(FileBundle()).loadMeta()), and an older build refuses a version-2 file
// through its own rule `version > kBackupVersion` (lib/backup/backup_service.dart before this feature, `_parse`).
import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/motion_probe.dart' show FileBundle;

/// What today's code (before feature 013) exported for the database of [seedPageOnly], with every time replaced by
/// `<time>` (the times are written in the phone's own offset). Captured from the unchanged `BackupService` on 2026-11-25.
const String kVersion1Bytes = '''{
  "app": "mushaf-hafiz",
  "version": 1,
  "exportedAt": "<time>",
  "wirds": [
    {
      "id": 1,
      "name": "الورد اليومي",
      "type": "reading",
      "currentPage": 1,
      "dailyPages": 20,
      "targetDate": null,
      "khatmaCount": 0,
      "notifyEnabled": true,
      "notifyMinutes": 1200,
      "color": 4281236786,
      "sortOrder": 0,
      "createdAt": "<time>"
    }
  ],
  "wirdDays": [],
  "bookmarks": [
    {
      "id": 1,
      "wirdId": 1,
      "page": 48,
      "note": "صفحة",
      "createdAt": "<time>"
    },
    {
      "id": 2,
      "wirdId": null,
      "page": 604,
      "note": null,
      "createdAt": "<time>"
    }
  ],
  "settings": {
    "activeWirdId": "1",
    "defaultsCreated": "true",
    "textSizePercent": "120"
  }
}''';

String withoutTimes(String json) => json.replaceAll(
  RegExp(r'\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d'),
  '<time>',
);

/// The database the golden bytes above were made from.
Future<void> seedPageOnly(AppDatabase db) async {
  await WirdRepository(db).ensureDefaults();
  await db
      .into(db.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          page: 48,
          wirdId: const Value(1),
          note: const Value('صفحة'),
          createdAt: Value(DateTime.utc(2026, 11, 1, 8)),
        ),
      );
  await db
      .into(db.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          page: 604,
          createdAt: Value(DateTime.utc(2026, 11, 2, 9, 30)),
        ),
      );
  await WirdRepository(db).setTextSizePercent(120);
}

/// Every row, as plain data.
Future<Map<String, Object?>> snapshot(AppDatabase db) async => {
  'wirds': [for (final w in await db.select(db.wirds).get()) w.toJson()],
  'days': [for (final d in await db.select(db.wirdDays).get()) d.toJson()],
  'marks': [
    for (final b in await (db.select(
      db.bookmarks,
    )..orderBy([(b) => OrderingTerm.asc(b.id)])).get())
      (
        b.id,
        b.wirdId,
        b.page,
        b.note,
        b.createdAt.millisecondsSinceEpoch,
        b.surah,
        b.ayah,
      ),
  ],
  'settings': {
    for (final s in await db.select(db.settings).get()) s.key: s.value,
  },
};

void main() {
  late MushafMeta meta;
  late AppDatabase db;
  late WirdRepository repo;
  late BackupService backup;
  final now = DateTime(2026, 11, 25, 12);

  setUpAll(() async {
    meta = await MushafRepository(FileBundle()).loadMeta();
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    backup = BackupService(db, meta: meta);
  });
  tearDown(() => db.close());

  Future<int> ayah(AyahRef ref, {int? wirdId, String? note}) async {
    final page = meta.pageOfAyah(ref.surah, ref.ayah);
    final id = (await repo.toggleAyahBookmark(
      ref,
      page: page,
      wirdId: wirdId,
    )).addedId!;
    if (note != null) {
      await repo.saveAyahNote(ref, page: page, wirdId: wirdId, note: note);
    }
    return id;
  }

  /// Three scopes (general and two wirds), at least 20 ayah bookmarks with and without notes, page bookmarks, settings.
  Future<void> fillWithAyat(AppDatabase target) async {
    final r = WirdRepository(target);
    await r.ensureDefaults();
    final second = await r.create(
      const WirdDraft(
        name: 'حفظ',
        type: WirdType.hifz,
        dailyPages: 1,
        color: 0xFF6A1B9A,
      ),
    );
    final scopes = <int?>[null, 1, second];
    final refs = [
      const AyahRef(1, 1),
      const AyahRef(1, 7),
      const AyahRef(2, 255),
      const AyahRef(2, 282),
      const AyahRef(2, 286),
      const AyahRef(3, 1),
      const AyahRef(18, 10),
      const AyahRef(36, 1),
      const AyahRef(67, 1),
      const AyahRef(114, 6),
    ];
    var i = 0;
    for (final ref in refs) {
      for (final scope in scopes.take(i.isEven ? 3 : 2)) {
        final page = meta.pageOfAyah(ref.surah, ref.ayah);
        if (i % 3 == 0) {
          await r.saveAyahNote(
            ref,
            page: page,
            wirdId: scope,
            note: 'ملاحظة $i على ${ref.key}',
          );
        } else {
          await r.toggleAyahBookmark(ref, page: page, wirdId: scope);
        }
      }
      i++;
    }
    await r.addBookmark(77, 'صفحة', wirdId: 1);
    await r.addBookmark(293, null);
    await r.setAyahTint(false);
    await r.setTextSizePercent(150);
  }

  group('export', () {
    test('with no ayah bookmark it is exactly today\'s version-1 file, no surah or ayah key', () async {
      await seedPageOnly(db);
      final text = await backup.exportJson(now: now);
      expect(withoutTimes(text), kVersion1Bytes);
      final map = jsonDecode(text) as Map<String, dynamic>;
      expect(map['version'], 1);
      for (final b in map['bookmarks'] as List<dynamic>) {
        expect((b as Map).containsKey('surah'), isFalse);
        expect(b.containsKey('ayah'), isFalse);
      }
      expect(kBackupVersion, 1, reason: 'the base format keeps its number');
    });

    test(
      'with one ayah bookmark it is version 2 and every bookmark has both keys',
      () async {
        await seedPageOnly(db);
        await ayah(const AyahRef(2, 282), wirdId: 1);
        final map = jsonDecode(
          await backup.exportJson(now: now),
        ) as Map<String, dynamic>;
        expect(map['version'], kBackupVersionAyah);
        expect(map['version'], 2);
        final marks = [
          for (final b in map['bookmarks'] as List<dynamic>)
            b as Map<String, dynamic>,
        ];
        expect(marks, hasLength(3));
        for (final b in marks) {
          expect(
            b.keys,
            containsAll([
              'id',
              'wirdId',
              'page',
              'note',
              'createdAt',
              'surah',
              'ayah',
            ]),
          );
        }
        expect(
          [for (final b in marks) (b['surah'], b['ayah'], b['page'])],
          [(null, null, 48), (null, null, 604), (2, 282, 48)],
        );
      },
    );

    test(
      'an older build refuses the version-2 file through its own rule',
      () async {
        await ayah(const AyahRef(2, 282));
        final map = jsonDecode(
          await backup.exportJson(now: now),
        ) as Map<String, dynamic>;
        // lib/backup/backup_service.dart before feature 013: `if (version > kBackupVersion)` with kBackupVersion = 1 throws
        // BackupProblem.newerVersion, shown as «هذه النسخة الاحتياطية أحدث من هذا التطبيق. لم يتغيّر شيء.».
        const oldBuildVersion = 1;
        expect(map['version'] as int > oldBuildVersion, isTrue);
        expect(kBackupHighestRead, 2);
      },
    );
  });

  group('round trip', () {
    test('20 and more ayah bookmarks in 3 scopes with notes come back equal, the switch too', () async {
      await fillWithAyat(db);
      final ayat = (await db.select(db.bookmarks).get()).where(
        (b) => b.surah != null,
      );
      expect(ayat.length, greaterThanOrEqualTo(20));
      expect({for (final b in ayat) b.wirdId}, hasLength(3));
      expect(ayat.where((b) => b.note != null), isNotEmpty);
      final file = await backup.exportJson(now: now);
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await BackupService(other, meta: meta).importJson(file);
      expect(await snapshot(other), await snapshot(db));
      expect(await WirdRepository(other).ayahTintRaw(), 'false');
    });

    test(
      'a version-1 file restores completely, its bookmarks are page bookmarks',
      () async {
        await seedPageOnly(db);
        final file = await BackupService(db).exportJson(now: now);
        expect((jsonDecode(file) as Map)['version'], 1);
        final other = AppDatabase(NativeDatabase.memory());
        addTearDown(other.close);
        await BackupService(other, meta: meta).importJson(file);
        expect(await snapshot(other), await snapshot(db));
        expect(
          (await other.select(other.bookmarks).get()).where(
            (b) => b.surah != null || b.ayah != null,
          ),
          isEmpty,
        );
      },
    );
  });

  group('refused, and nothing changes', () {
    late String good;
    late Map<String, Object?> before;

    setUp(() async {
      await fillWithAyat(db);
      good = await backup.exportJson(now: now);
      before = await snapshot(db);
    });

    Future<void> expectRefused(
      String file,
      BackupProblem problem, {
      BackupService? service,
    }) async {
      final s = service ?? backup;
      expect(
        () => s.check(file),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.problem,
            'problem',
            problem,
          ),
        ),
      );
      await expectLater(
        s.importJson(file),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.problem,
            'problem',
            problem,
          ),
        ),
      );
      expect(await snapshot(db), before, reason: 'nothing changed');
    }

    Map<String, dynamic> edited(void Function(Map<String, dynamic> m) change) {
      final m = jsonDecode(good) as Map<String, dynamic>;
      change(m);
      return m;
    }

    Map<String, dynamic> firstAyah(Map<String, dynamic> m) =>
        (m['bookmarks'] as List).cast<Map<String, dynamic>>().firstWhere(
          (b) => b['surah'] != null,
        );
    Map<String, dynamic> firstPage(Map<String, dynamic> m) =>
        (m['bookmarks'] as List).cast<Map<String, dynamic>>().firstWhere(
          (b) => b['surah'] == null,
        );

    test(
      'a version-1 file that carries a surah or an ayah is invalid',
      () async {
        await expectRefused(
          jsonEncode(edited((m) => m['version'] = 1)),
          BackupProblem.invalid,
        );
        // A real version-1 file (page bookmarks only) with a surah and an ayah written into one bookmark.
        final pageOnly = AppDatabase(NativeDatabase.memory());
        addTearDown(pageOnly.close);
        await seedPageOnly(pageOnly);
        final v1 = jsonDecode(
          await BackupService(pageOnly).exportJson(now: now),
        ) as Map<String, dynamic>;
        expect(v1['version'], 1);
        final mark = (v1['bookmarks'] as List).first as Map<String, dynamic>;
        expect(mark['page'], 48);
        await expectRefused(
          jsonEncode(
            v1
              ..['bookmarks'] = [
                mark
                  ..['surah'] = 2
                  ..['ayah'] = 282,
              ],
          ),
          BackupProblem.invalid,
        );
        await expectRefused(
          jsonEncode(v1..['bookmarks'] = [mark..remove('surah')]),
          BackupProblem.invalid,
        );
      },
    );

    test('an ayah that does not exist (2:287), a surah alone, an ayah alone, a wrong page, surah 0 or 115', () async {
      await expectRefused(
        jsonEncode(
          edited(
            (m) => firstAyah(m)
              ..['surah'] = 2
              ..['ayah'] = 287,
          ),
        ),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(edited((m) => firstAyah(m)['ayah'] = null)),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(edited((m) => firstAyah(m).remove('ayah'))),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(edited((m) => firstAyah(m)['surah'] = null)),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(
          edited(
            (m) => firstAyah(m)
              ..['surah'] = 2
              ..['ayah'] = 282
              ..['page'] = 49,
          ),
        ),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(edited((m) => firstAyah(m)['surah'] = 0)),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(edited((m) => firstAyah(m)['surah'] = 115)),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(edited((m) => firstAyah(m)['ayah'] = 0)),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(edited((m) => firstAyah(m)['ayah'] = '1')),
        BackupProblem.invalid,
      );
      await expectRefused(
        jsonEncode(edited((m) => firstPage(m)['surah'] = 1)),
        BackupProblem.invalid,
      );
    });

    test('version 3 is newer and changes nothing', () async {
      await expectRefused(
        jsonEncode(edited((m) => m['version'] = 3)),
        BackupProblem.newerVersion,
      );
    });

    test(
      'a file with an ayah bookmark and a service with no meta is invalid',
      () async {
        await expectRefused(
          good,
          BackupProblem.invalid,
          service: BackupService(db),
        );
      },
    );

    test('an import that fails halfway changes nothing', () async {
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await seedPageOnly(other);
      final otherBefore = await snapshot(other);
      for (final stage in ['cleared', 'wirds', 'wirdDays', 'bookmarks']) {
        final failing = BackupService(
          other,
          meta: meta,
          debugHook: (s) async {
            if (s == stage) throw StateError('disk full at $stage');
          },
        );
        await expectLater(failing.importJson(good), throwsStateError);
        expect(
          await snapshot(other),
          otherBefore,
          reason: 'rolled back after $stage',
        );
      }
    });
  });

  test('the helper used above makes real ayah bookmarks', () async {
    final id = await ayah(const AyahRef(2, 282), wirdId: null, note: 'x');
    final b = (await db.select(db.bookmarks).get()).single;
    expect((b.id, b.surah, b.ayah, b.page, b.note), (id, 2, 282, 48, 'x'));
  });
}
