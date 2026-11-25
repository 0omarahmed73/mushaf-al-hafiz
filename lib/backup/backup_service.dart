import 'dart:convert';

import 'package:drift/drift.dart';

import '../mushaf/models.dart';
import '../wirds/db.dart';
import '../wirds/portion.dart';

/// `app` value of a backup file; a file with any other value comes from another app.
const String kBackupApp = 'mushaf-hafiz';

/// The base backup format: what the app writes when no bookmark is an ayah bookmark (byte for byte what it wrote before
/// feature 013), and what an older build reads.
const int kBackupVersion = 1;

/// The format that carries the surah and the ayah of an ayah bookmark (feature 013, research D3): written only when at
/// least one exists, so a file with page bookmarks only stays readable by an older build.
const int kBackupVersionAyah = 2;

/// The highest version this app reads; a file above it is [BackupProblem.newerVersion].
const int kBackupHighestRead = kBackupVersionAyah;

/// Why a file was refused (contracts/backup-file.md).
enum BackupProblem {
  /// Another app's file, or not a backup object at all.
  notABackup,

  /// Written by a newer version of this app.
  newerVersion,

  /// Malformed JSON, a missing or odd field, a page outside 1–604, rows that do not fit together.
  invalid,
}

/// A backup file that cannot be imported. Nothing was changed.
class BackupFormatException extends FormatException {
  const BackupFormatException(this.problem, String message) : super(message);

  final BackupProblem problem;
}

/// `mushaf-backup-YYYY-MM-DD.json` for the local date [localNow].
String backupFileName(DateTime localNow) =>
    'mushaf-backup-${dayKey(localNow)}.json';

/// Settings that describe this phone rather than the user's data. A backup replaces every setting, but when the file has
/// no value for one of these keys the phone's own value is kept: importing a file written before the key existed must not
/// make the phone forget it (feature 008: `tipsSeen`, so the first-run tips do not show again after a restore). A value the
/// file does carry wins.
const Set<String> kKeptOnImport = {'tipsSeen'};

/// Exports every user table and setting as one JSON document and restores such a document, replacing
/// everything in one transaction (spec FR-039, FR-040).
class BackupService {
  /// [debugHook] is called with 'cleared', 'wirds', 'wirdDays' and 'bookmarks' during an import, so a
  /// test can make the import fail halfway. [meta] is the fixed edition's data the ayah bookmarks of a file are checked
  /// against (the ayah exists, the page is where it begins); without it a file with an ayah bookmark is refused.
  BackupService(this._db, {this.debugHook, this.meta});

  final AppDatabase _db;
  final Future<void> Function(String stage)? debugHook;
  final MushafMeta? meta;

  // ------------------------------------------------------------------ export

  Future<String> exportJson({DateTime? now}) async {
    final wirds = await (_db.select(
      _db.wirds,
    )..orderBy([(w) => OrderingTerm.asc(w.id)])).get();
    final days =
        await (_db.select(_db.wirdDays)..orderBy([
              (d) => OrderingTerm.asc(d.wirdId),
              (d) => OrderingTerm.asc(d.day),
            ]))
            .get();
    final marks = await (_db.select(
      _db.bookmarks,
    )..orderBy([(b) => OrderingTerm.asc(b.id)])).get();
    final settings = await (_db.select(
      _db.settings,
    )..orderBy([(s) => OrderingTerm.asc(s.key)])).get();
    final ayat = marks.any((b) => b.surah != null);
    return const JsonEncoder.withIndent('  ').convert({
      'app': kBackupApp,
      'version': ayat ? kBackupVersionAyah : kBackupVersion,
      'exportedAt': _iso(now ?? DateTime.now()),
      'wirds': [
        for (final w in wirds)
          {
            'id': w.id,
            'name': w.name,
            'type': w.type.name,
            'currentPage': w.currentPage,
            'dailyPages': w.dailyPages,
            'targetDate': w.targetDate == null ? null : dayKey(w.targetDate!),
            'khatmaCount': w.khatmaCount,
            'notifyEnabled': w.notifyEnabled,
            'notifyMinutes': w.notifyMinutes,
            'color': w.color,
            'sortOrder': w.sortOrder,
            'createdAt': _iso(w.createdAt),
          },
      ],
      'wirdDays': [
        for (final d in days)
          {
            'wirdId': d.wirdId,
            'day': d.day,
            'startPage': d.startPage,
            'endPage': d.endPage,
            'done': d.done,
          },
      ],
      'bookmarks': [
        for (final b in marks)
          {
            'id': b.id,
            'wirdId': b.wirdId,
            'page': b.page,
            'note': b.note,
            'createdAt': _iso(b.createdAt),
            if (ayat) 'surah': b.surah,
            if (ayat) 'ayah': b.ayah,
          },
      ],
      'settings': {for (final s in settings) s.key: s.value},
    });
  }

  // ------------------------------------------------------------------ import

  /// Throws [BackupFormatException] if [text] is not a backup this app can import; changes nothing.
  void check(String text) => _parse(text, meta);

  /// Replaces every wird, portion, bookmark and setting with the file's. The file is checked first;
  /// if it is refused, or anything fails on the way, nothing changes.
  Future<void> importJson(String text) async {
    final data = _parse(text, meta);
    await _db.transaction(() async {
      final kept = await (_db.select(
        _db.settings,
      )..where((s) => s.key.isIn(kKeptOnImport))).get();
      await _db.delete(_db.bookmarks).go();
      await _db.delete(_db.wirdDays).go();
      await _db.delete(_db.wirds).go();
      await _db.delete(_db.settings).go();
      await debugHook?.call('cleared');
      for (final w in data.wirds) {
        await _db.into(_db.wirds).insert(w);
      }
      await debugHook?.call('wirds');
      for (final d in data.days) {
        await _db.into(_db.wirdDays).insert(d);
      }
      await debugHook?.call('wirdDays');
      for (final b in data.bookmarks) {
        await _db.into(_db.bookmarks).insert(b);
      }
      await debugHook?.call('bookmarks');
      for (final e in data.settings.entries) {
        await _db
            .into(_db.settings)
            .insert(SettingsCompanion.insert(key: e.key, value: e.value));
      }
      for (final s in kept) {
        if (data.settings.containsKey(s.key)) continue;
        await _db
            .into(_db.settings)
            .insert(SettingsCompanion.insert(key: s.key, value: s.value));
      }
    });
  }
}

// -------------------------------------------------------------------- parsing

class _Parsed {
  _Parsed(this.wirds, this.days, this.bookmarks, this.settings);

  final List<WirdsCompanion> wirds;
  final List<WirdDaysCompanion> days;
  final List<BookmarksCompanion> bookmarks;
  final Map<String, String> settings;
}

BackupFormatException _bad(String message) =>
    BackupFormatException(BackupProblem.invalid, message);

_Parsed _parse(String text, MushafMeta? meta) {
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    throw _bad('not valid JSON');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const BackupFormatException(
      BackupProblem.notABackup,
      'not a backup object',
    );
  }
  if (decoded['app'] != kBackupApp) {
    throw const BackupFormatException(
      BackupProblem.notABackup,
      'written by another app',
    );
  }
  final version = decoded['version'];
  if (version is! int || version < 1) throw _bad('missing or odd version');
  if (version > kBackupHighestRead) {
    throw const BackupFormatException(
      BackupProblem.newerVersion,
      'written by a newer version',
    );
  }

  final wirds = <WirdsCompanion>[];
  final wirdIds = <int>{};
  for (final m in _rows(decoded, 'wirds')) {
    final id = _int(m, 'id', min: 1);
    if (!wirdIds.add(id)) throw _bad('wird id $id twice');
    final name = _string(m, 'name');
    if (name.trim().isEmpty || name.length > 100) throw _bad('wird name');
    final typeName = _string(m, 'type');
    final type = WirdType.values.where((t) => t.name == typeName).firstOrNull;
    if (type == null) throw _bad('wird type $typeName');
    wirds.add(
      WirdsCompanion.insert(
        id: Value(id),
        name: name,
        type: type,
        currentPage: Value(_int(m, 'currentPage', min: 1, max: 604)),
        dailyPages: Value(_intOrNull(m, 'dailyPages', min: 1)),
        targetDate: Value(_dateOrNull(m, 'targetDate')),
        khatmaCount: Value(_int(m, 'khatmaCount', min: 0)),
        notifyEnabled: Value(_bool(m, 'notifyEnabled')),
        notifyMinutes: Value(_intOrNull(m, 'notifyMinutes', min: 0, max: 1439)),
        color: _int(m, 'color'),
        sortOrder: Value(_int(m, 'sortOrder')),
        createdAt: Value(_instant(m, 'createdAt')),
      ),
    );
  }

  final days = <WirdDaysCompanion>[];
  final dayKeys = <String>{};
  for (final m in _rows(decoded, 'wirdDays')) {
    final wirdId = _int(m, 'wirdId');
    if (!wirdIds.contains(wirdId)) {
      throw _bad('portion of unknown wird $wirdId');
    }
    final day = _string(m, 'day');
    if (!_isDay(day)) throw _bad('portion day $day');
    if (!dayKeys.add('$wirdId/$day')) throw _bad('portion $wirdId/$day twice');
    final start = _int(m, 'startPage', min: 1, max: 604);
    final end = _int(m, 'endPage', min: 1, max: 604);
    if (end < start) throw _bad('portion ends before it starts');
    days.add(
      WirdDaysCompanion.insert(
        wirdId: wirdId,
        day: day,
        startPage: start,
        endPage: end,
        done: Value(_bool(m, 'done')),
      ),
    );
  }

  final bookmarks = <BookmarksCompanion>[];
  final bookmarkIds = <int>{};
  for (final m in _rows(decoded, 'bookmarks')) {
    final id = _int(m, 'id', min: 1);
    if (!bookmarkIds.add(id)) throw _bad('bookmark id $id twice');
    final wirdId = _intOrNull(m, 'wirdId');
    if (wirdId != null && !wirdIds.contains(wirdId)) {
      throw _bad('bookmark of unknown wird $wirdId');
    }
    final note = m['note'];
    if (note != null && note is! String) throw _bad('bookmark note');
    final page = _int(m, 'page', min: 1, max: 604);
    final ayah = _ayahOf(m, version, page, meta);
    bookmarks.add(
      BookmarksCompanion.insert(
        id: Value(id),
        wirdId: Value(wirdId),
        page: page,
        note: Value(note as String?),
        createdAt: Value(_instant(m, 'createdAt')),
        surah: Value(ayah?.surah),
        ayah: Value(ayah?.ayah),
      ),
    );
  }

  final rawSettings = decoded['settings'];
  if (rawSettings is! Map<String, dynamic>) throw _bad('settings');
  final settings = <String, String>{};
  for (final e in rawSettings.entries) {
    final v = e.value;
    if (v is! String) throw _bad('setting ${e.key}');
    settings[e.key] = v;
  }
  final active = settings['activeWirdId'];
  if (active != null && !wirdIds.contains(int.tryParse(active))) {
    throw _bad('active wird is not in the file');
  }

  return _Parsed(wirds, days, bookmarks, settings);
}

/// The ayah of a bookmark row, or null for a page bookmark (feature 013, data-model.md Backup file). A version-1 file never
/// carries one; in version 2 `surah` and `ayah` are both absent or null, or both whole numbers of an ayah that exists in
/// the fixed edition whose page is [page]. Anything else, or an ayah with no [meta] to check it against, is invalid.
({int surah, int ayah})? _ayahOf(
  Map<String, dynamic> m,
  int version,
  int page,
  MushafMeta? meta,
) {
  if (m['surah'] == null && m['ayah'] == null) return null;
  if (version < kBackupVersionAyah) throw _bad('an ayah in a version-1 file');
  if (m['surah'] == null || m['ayah'] == null) {
    throw _bad('a surah without an ayah, or an ayah without a surah');
  }
  final surah = _int(m, 'surah', min: 1, max: MushafMeta.surahCount);
  final ayah = _int(m, 'ayah', min: 1);
  if (meta == null) throw _bad('ayah bookmarks cannot be checked');
  if (ayah > meta.surah(surah).ayahs) throw _bad('no ayah $surah:$ayah');
  if (meta.pageOfAyah(surah, ayah) != page) {
    throw _bad('ayah $surah:$ayah does not begin on page $page');
  }
  return (surah: surah, ayah: ayah);
}

Iterable<Map<String, dynamic>> _rows(Map<String, dynamic> m, String key) {
  final list = m[key];
  if (list is! List) throw _bad('$key is not a list');
  return list.map((e) {
    if (e is! Map<String, dynamic>) {
      throw _bad('a row of $key is not an object');
    }
    return e;
  });
}

int _int(Map<String, dynamic> m, String key, {int? min, int? max}) {
  final v = m[key];
  if (v is! int) throw _bad('$key must be a whole number');
  if ((min != null && v < min) || (max != null && v > max)) {
    throw _bad('$key out of range');
  }
  return v;
}

int? _intOrNull(Map<String, dynamic> m, String key, {int? min, int? max}) =>
    m[key] == null ? null : _int(m, key, min: min, max: max);

String _string(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is! String) throw _bad('$key must be text');
  return v;
}

bool _bool(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is! bool) throw _bad('$key must be true or false');
  return v;
}

DateTime _instant(Map<String, dynamic> m, String key) {
  final v = DateTime.tryParse(_string(m, key));
  if (v == null) throw _bad('$key is not a date and time');
  return v;
}

final RegExp _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

bool _isDay(String s) {
  final m = _dayPattern.firstMatch(s);
  if (m == null) return false;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final back = DateTime(y, mo, d);
  return back.year == y && back.month == mo && back.day == d;
}

DateTime? _dateOrNull(Map<String, dynamic> m, String key) {
  if (m[key] == null) return null;
  final s = _string(m, key);
  if (!_isDay(s)) throw _bad('$key is not a date');
  final p = _dayPattern.firstMatch(s)!;
  return DateTime(int.parse(p[1]!), int.parse(p[2]!), int.parse(p[3]!));
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `2026-11-20T21:04:00+02:00`: the local time with its offset.
String _iso(DateTime t) {
  final d = t.toLocal();
  final off = d.timeZoneOffset;
  final abs = off.abs();
  return '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}'
      'T${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}'
      '${off.isNegative ? '-' : '+'}${_two(abs.inHours)}:${_two(abs.inMinutes % 60)}';
}
