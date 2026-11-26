import 'package:drift/drift.dart';

import '../ayah/ayah_ref.dart';
import '../reminders/kahf_day.dart';
import 'ayah_bookmark_change.dart';
import 'db.dart';
import 'portion.dart';
import 'wird_palette.dart';
import '../prayer/prayer_settings.dart';

export 'db.dart' show Bookmark, Wird, WirdDay, WirdType;

/// What the user enters in the wird form (also used for the first-launch wird).
class WirdDraft {
  const WirdDraft({
    required this.name,
    required this.type,
    this.startPage = 1,
    this.dailyPages,
    this.targetDate,
    this.notifyEnabled = false,
    this.notifyMinutes,
    required this.color,
  });

  final String name;
  final WirdType type;
  final int startPage;
  final int? dailyPages;
  final DateTime? targetDate;
  final bool notifyEnabled;
  final int? notifyMinutes;
  final int color;
}

/// What one tap on the reader's bookmark icon did, kept by the message so that «تراجع» can undo exactly that tap
/// (feature 006, data-model.md `BookmarkToggle`): exactly one of [addedId] and [removed] is set.
class BookmarkToggle {
  const BookmarkToggle.added(this.page, int id)
    : addedId = id,
      removed = const [];
  const BookmarkToggle.removed(this.page, this.removed) : addedId = null;

  /// The page the tap was on (1..604).
  final int page;

  /// The id of the bookmark the tap added, or null when it removed.
  final int? addedId;

  /// The rows the tap deleted; empty when it added.
  final List<Bookmark> removed;

  bool get wasAdded => addedId != null;
}

/// A wird with its portion for today and whether it is done.
class TodayEntry {
  const TodayEntry({required this.wird, required this.day});

  final Wird wird;
  final WirdDay day;

  bool get done => isDonePortion(
    done: day.done,
    endPage: day.endPage,
    currentPage: wird.currentPage,
  );
}

/// A bookmark with the name of the wird it belongs to; [wirdName] is null for a general («عامة»)
/// bookmark, including one whose wird was deleted.
class BookmarkEntry {
  const BookmarkEntry({required this.bookmark, required this.wirdName});

  final Bookmark bookmark;
  final String? wirdName;
}

/// Everything `planReminders` reads from the database (see [WirdRepository.reminderInputs]).
class ReminderInputs {
  const ReminderInputs({
    required this.wirds,
    required this.doneToday,
    required this.todayPortions,
    required this.kahfEnabled,
    required this.kahfMinutes,
    this.kahfDay = KahfDay.thursday,
  });

  final List<Wird> wirds;
  final Map<int, bool> doneToday;
  final Map<int, ({int start, int end})> todayPortions;
  final bool kahfEnabled;
  final int kahfMinutes;

  /// The weekday of the al-Kahf reminder (feature 007); Thursday when the setting was never made.
  final KahfDay kahfDay;
}

/// Reads and writes the user's wirds, positions, bookmarks and settings (data-model.md).
class WirdRepository {
  WirdRepository(this._db);

  final AppDatabase _db;

  static const String defaultWirdName = 'الورد اليومي';
  static const int defaultDailyPages = 20;
  static const int defaultReminderMinutes = 20 * 60;

  /// al-Kahf is reminded on Thursday evening, the night of Friday. This is Thursday's default hour; Friday's is
  /// `KahfDay.friday.defaultMinutes` and the one in use is [kahfMinutes].
  static const int defaultKahfMinutes = 21 * 60;

  static const _kActive = 'activeWirdId';
  static const _kLastViewed = 'lastViewedPage';
  static const _kKahfEnabled = 'kahfEnabled';
  static const _kKahfMinutes = 'kahfMinutes';
  static const _kKahfDay = 'kahfDay';
  static const _kDefaultsCreated = 'defaultsCreated';
  static const _kPanelExpanded = 'todayPanelExpanded';
  static const _kPermissionAsked = 'notificationPermissionAsked';
  static const _kTextSize = 'textSizePercent';
  static const _kAppLook = 'appLook';
  static const _kAyahTint = 'ayahTint';
  static const _kLargeAyah = 'largeAyah';
  static const _kLargeAyahCount = 'largeAyahCount';
  static const _kLargeAyahSize = 'largeAyahSize';
  static const _kLargeAyahAt = 'largeAyahAt';

  // ------------------------------------------------------------------ settings

  Future<String?> _getSetting(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _setSetting(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> _removeSetting(String key) =>
      (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();

  // ------------------------------------------------------------------ validation

  static void _checkPage(int page, [String name = 'page']) {
    if (page < 1 || page > 604) {
      throw ArgumentError.value(page, name, 'must be between 1 and 604');
    }
  }

  static void _validate(WirdDraft d) {
    if (d.name.trim().isEmpty) {
      throw ArgumentError.value(d.name, 'name', 'must not be empty');
    }
    _checkPage(d.startPage, 'startPage');
    final daily = d.dailyPages;
    if (daily != null && daily < 1) {
      throw ArgumentError.value(daily, 'dailyPages', 'must be at least 1');
    }
    final minutes = d.notifyMinutes;
    if (minutes != null && (minutes < 0 || minutes > 1439)) {
      throw ArgumentError.value(minutes, 'notifyMinutes', 'must be 0..1439');
    }
  }

  static DateTime? _dateOnly(DateTime? d) =>
      d == null ? null : DateTime(d.year, d.month, d.day);

  // ------------------------------------------------------------------ first launch

  /// Creates «الورد اليومي» on the very first launch only (idempotent; never recreated afterwards,
  /// even if the user deletes every wird).
  Future<void> ensureDefaults() => _db.transaction(() async {
    if (await _getSetting(_kDefaultsCreated) == 'true') return;
    final id = await _insert(
      const WirdDraft(
        name: defaultWirdName,
        type: WirdType.reading,
        dailyPages: defaultDailyPages,
        notifyEnabled: true,
        notifyMinutes: defaultReminderMinutes,
        color: 0xFF2E7D32,
      ),
    );
    await _setSetting(_kActive, '$id');
    await _setSetting(_kDefaultsCreated, 'true');
  });

  // ------------------------------------------------------------------ wirds

  Stream<List<Wird>> watchWirds() =>
      (_db.select(_db.wirds)..orderBy([
            (w) => OrderingTerm.asc(w.sortOrder),
            (w) => OrderingTerm.asc(w.id),
          ]))
          .watch();

  Future<Wird?> wirdById(int id) =>
      (_db.select(_db.wirds)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<int> _insert(WirdDraft d) async {
    _validate(d);
    final maxOrder =
        await (_db.selectOnly(_db.wirds)
              ..addColumns([_db.wirds.sortOrder.max()]))
            .map((r) => r.read(_db.wirds.sortOrder.max()))
            .getSingleOrNull();
    return _db
        .into(_db.wirds)
        .insert(
          WirdsCompanion.insert(
            name: d.name.trim(),
            type: d.type,
            currentPage: Value(d.startPage),
            dailyPages: Value(d.dailyPages),
            targetDate: Value(_dateOnly(d.targetDate)),
            notifyEnabled: Value(d.notifyEnabled),
            notifyMinutes: Value(d.notifyMinutes),
            color: d.color,
            sortOrder: Value((maxOrder ?? -1) + 1),
          ),
        );
  }

  Future<int> create(WirdDraft d) => _insert(d);

  /// Updates the wird's fields. Editing the start page moves the position immediately and recreates an
  /// open portion from it; editing the goal recalculates an open portion's end (its start stays); a
  /// done portion never changes (spec FR-029).
  Future<void> update(int id, WirdDraft d, {DateTime? now}) async {
    _validate(d);
    await _db.transaction(() async {
      final old = await wirdById(id);
      if (old == null) throw ArgumentError.value(id, 'id', 'no such wird');
      await (_db.update(_db.wirds)..where((w) => w.id.equals(id))).write(
        WirdsCompanion(
          name: Value(d.name.trim()),
          type: Value(d.type),
          currentPage: Value(d.startPage),
          dailyPages: Value(d.dailyPages),
          targetDate: Value(_dateOnly(d.targetDate)),
          notifyEnabled: Value(d.notifyEnabled),
          notifyMinutes: Value(d.notifyMinutes),
          color: Value(d.color),
        ),
      );
      final key = wirdDayKey(d.type, now ?? DateTime.now());
      final row = await _dayRow(id, key);
      if (row == null || row.done) return;
      if (d.startPage != old.currentPage) {
        await _deleteDay(id, key);
      } else if (d.dailyPages != old.dailyPages ||
          _dateOnly(d.targetDate) != old.targetDate) {
        final perDay = pagesPerDay(
          currentPage: row.startPage,
          dailyPages: d.dailyPages,
          targetDate: _dateOnly(d.targetDate),
          today: _parseDay(key),
        );
        final p = portionFor(startPage: row.startPage, perDay: perDay);
        await (_db.update(_db.wirdDays)
              ..where((t) => t.wirdId.equals(id) & t.day.equals(key)))
            .write(WirdDaysCompanion(endPage: Value(p.end)));
      }
    });
  }

  /// Deletes the wird (its portions are deleted, its bookmarks become general). If it was active,
  /// the first remaining wird in list order becomes active, or none.
  Future<void> delete(int id) => _db.transaction(() async {
    await (_db.delete(_db.wirds)..where((w) => w.id.equals(id))).go();
    if (await _getSetting(_kActive) == '$id') {
      final first =
          await (_db.select(_db.wirds)
                ..orderBy([
                  (w) => OrderingTerm.asc(w.sortOrder),
                  (w) => OrderingTerm.asc(w.id),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (first == null) {
        await _removeSetting(_kActive);
      } else {
        await _setSetting(_kActive, '${first.id}');
      }
    }
  });

  Future<Wird?> activeWird() async {
    final raw = await _getSetting(_kActive);
    final id = raw == null ? null : int.tryParse(raw);
    return id == null ? null : wirdById(id);
  }

  Future<void> setActive(int id) async {
    if (await wirdById(id) == null) {
      throw ArgumentError.value(id, 'id', 'no such wird');
    }
    await _setSetting(_kActive, '$id');
  }

  /// Moves one wird's position. Throws [ArgumentError] outside 1..604.
  Future<void> setPage(int wirdId, int page) async {
    _checkPage(page);
    await (_db.update(_db.wirds)..where((w) => w.id.equals(wirdId))).write(
      WirdsCompanion(currentPage: Value(page)),
    );
  }

  // ------------------------------------------------------------------ today's portion

  static DateTime _parseDay(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  Future<WirdDay?> _dayRow(int wirdId, String key) =>
      (_db.select(_db.wirdDays)
            ..where((t) => t.wirdId.equals(wirdId) & t.day.equals(key)))
          .getSingleOrNull();

  Future<void> _deleteDay(int wirdId, String key) => (_db.delete(
    _db.wirdDays,
  )..where((t) => t.wirdId.equals(wirdId) & t.day.equals(key))).go();

  /// The wird's portion for the wird day [now] falls in. Created the first time it is needed, from
  /// the wird's position then, and unchanged for the rest of that day.
  Future<WirdDay> today(int wirdId, DateTime now) => _db.transaction(() async {
    final wird = await wirdById(wirdId);
    if (wird == null) {
      throw ArgumentError.value(wirdId, 'wirdId', 'no such wird');
    }
    final key = wirdDayKey(wird.type, now);
    final existing = await _dayRow(wirdId, key);
    if (existing != null) return existing;
    final perDay = pagesPerDay(
      currentPage: wird.currentPage,
      dailyPages: wird.dailyPages,
      targetDate: wird.targetDate,
      today: _parseDay(key),
    );
    final p = portionFor(startPage: wird.currentPage, perDay: perDay);
    await _db
        .into(_db.wirdDays)
        .insert(
          WirdDaysCompanion.insert(
            wirdId: wirdId,
            day: key,
            startPage: p.start,
            endPage: p.end,
          ),
        );
    return (await _dayRow(wirdId, key))!;
  });

  /// «تم»: marks today's portion done and, if the wird has not read past it, moves it to the page
  /// after the portion (finishing the khatma and restarting at page 1 after page 604).
  Future<void> markDone(int wirdId, DateTime now) => _db.transaction(() async {
    final row = await today(wirdId, now);
    final wird = (await wirdById(wirdId))!;
    await (_db.update(_db.wirdDays)
          ..where((t) => t.wirdId.equals(wirdId) & t.day.equals(row.day)))
        .write(const WirdDaysCompanion(done: Value(true)));
    if (wird.currentPage <= row.endPage) {
      final next = afterDone(row.endPage);
      await (_db.update(_db.wirds)..where((w) => w.id.equals(wirdId))).write(
        WirdsCompanion(
          currentPage: Value(next.nextPage),
          khatmaCount: Value(wird.khatmaCount + (next.completedKhatma ? 1 : 0)),
        ),
      );
    }
  });

  /// Reading and qiyam wirds in list order, each with today's portion.
  Future<List<TodayEntry>> todayEntries(DateTime now) async {
    final wirds =
        await (_db.select(_db.wirds)
              ..where(
                (w) =>
                    w.type.equals(WirdType.reading.name) |
                    w.type.equals(WirdType.qiyam.name),
              )
              ..orderBy([
                (w) => OrderingTerm.asc(w.sortOrder),
                (w) => OrderingTerm.asc(w.id),
              ]))
            .get();
    final entries = <TodayEntry>[];
    for (final w in wirds) {
      final day = await today(w.id, now);
      entries.add(TodayEntry(wird: (await wirdById(w.id))!, day: day));
    }
    return entries;
  }

  /// [todayEntries] again whenever a wird or a portion changes.
  Stream<List<TodayEntry>> watchTodayEntries({DateTime Function()? clock}) {
    final now = clock ?? DateTime.now;
    return _db
        .customSelect('select 1', readsFrom: {_db.wirds, _db.wirdDays})
        .watch()
        .asyncMap((_) => todayEntries(now()));
  }

  /// What the reminder planner needs, read without creating or changing anything: every wird,
  /// which of the reading and qiyam wirds are done for their current wird day, and the portion of
  /// that day where one already exists.
  Future<ReminderInputs> reminderInputs(DateTime now) async {
    final wirds =
        await (_db.select(_db.wirds)..orderBy([
              (w) => OrderingTerm.asc(w.sortOrder),
              (w) => OrderingTerm.asc(w.id),
            ]))
            .get();
    final done = <int, bool>{};
    final portions = <int, ({int start, int end})>{};
    for (final w in wirds) {
      if (w.type != WirdType.reading && w.type != WirdType.qiyam) continue;
      final row = await _dayRow(w.id, wirdDayKey(w.type, now));
      if (row == null) continue;
      portions[w.id] = (start: row.startPage, end: row.endPage);
      done[w.id] = isDonePortion(
        done: row.done,
        endPage: row.endPage,
        currentPage: w.currentPage,
      );
    }
    // The day is read once: the hour that follows it must be the one of the same day.
    final day = await kahfDay();
    return ReminderInputs(
      wirds: wirds,
      doneToday: done,
      todayPortions: portions,
      kahfEnabled: await kahfEnabled(),
      kahfMinutes: await _kahfMinutesFor(day),
      kahfDay: day,
    );
  }

  /// Emits whenever a wird, a portion or a setting changes, so the schedule can be refreshed.
  Stream<void> watchReminderInputs() => _db
      .customSelect(
        'select 1',
        readsFrom: {_db.wirds, _db.wirdDays, _db.settings},
      )
      .watch()
      .map((_) {});

  Future<bool> notificationPermissionAsked() async =>
      (await _getSetting(_kPermissionAsked)) == 'true';

  Future<void> setNotificationPermissionAsked() =>
      _setSetting(_kPermissionAsked, 'true');

  /// Adds a bookmark on [page] (1..604, else [ArgumentError]). A blank [note] is no note. A null
  /// [wirdId] makes it general («عامة»). Returns its id.
  Future<int> addBookmark(int page, String? note, {int? wirdId}) {
    _checkPage(page);
    final text = note?.trim();
    return _db
        .into(_db.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            page: page,
            wirdId: Value(wirdId),
            note: Value(text == null || text.isEmpty ? null : text),
          ),
        );
  }

  Future<void> removeBookmark(int id) =>
      (_db.delete(_db.bookmarks)..where((b) => b.id.equals(id))).go();

  /// A raw setting by key, for a feature that keeps one small flag in the settings table (the first-run tips use
  /// `tipsSeen`). The typed settings below stay the way to read the app's own settings.
  Future<String?> readSetting(String key) => _getSetting(key);

  /// Writes the raw setting [key].
  Future<void> writeSetting(String key, String value) =>
      _setSetting(key, value);

  /// Every bookmark, read once (no stream): the reader controller works out its icon state from these rows.
  Future<List<Bookmark>> bookmarkRows() => _db.select(_db.bookmarks).get();

  /// One tap on the reader's bookmark icon (feature 006): in one transaction, a page with no PAGE bookmark of the scope
  /// [wirdId] (null = the general ones) gets one with no note; a page that has some loses all of them. Decided from
  /// the database, never from what the screen believed. An ayah bookmark (feature 013) is never read, counted or
  /// deleted here (spec FR-011). [ArgumentError] when [page] is not 1..604.
  Future<BookmarkToggle> toggleBookmark(int page, {int? wirdId}) async {
    _checkPage(page);
    return _db.transaction(() async {
      final rows =
          await (_db.select(_db.bookmarks)..where(
                (b) =>
                    b.page.equals(page) &
                    b.surah.isNull() &
                    (wirdId == null
                        ? b.wirdId.isNull()
                        : b.wirdId.equals(wirdId)),
              ))
              .get();
      if (rows.isEmpty) {
        final id = await addBookmark(page, null, wirdId: wirdId);
        return BookmarkToggle.added(page, id);
      }
      await (_db.delete(
        _db.bookmarks,
      )..where((b) => b.id.isIn([for (final r in rows) r.id]))).go();
      return BookmarkToggle.removed(page, rows);
    });
  }

  /// Undoes [toggle]: deletes the bookmark it added, or puts back the rows it removed with their id, note and time
  /// (one whose wird no longer exists comes back general). A row that already exists is left as it is, so undoing
  /// twice changes nothing.
  Future<void> undoBookmarkToggle(BookmarkToggle toggle) => _db.transaction(
    () async {
      final added = toggle.addedId;
      if (added != null) {
        await removeBookmark(added);
        return;
      }
      final wirdIds = {for (final w in await _db.select(_db.wirds).get()) w.id};
      for (final r in toggle.removed) {
        await _db
            .into(_db.bookmarks)
            .insert(
              BookmarksCompanion.insert(
                id: Value(r.id),
                page: r.page,
                wirdId: Value(wirdIds.contains(r.wirdId) ? r.wirdId : null),
                note: Value(r.note),
                createdAt: Value(r.createdAt),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    },
  );

  // ------------------------------------------------------------------ ayah bookmarks (feature 013)

  /// The ayah bookmarks of [ref] in the scope [wirdId] (null = the general ones), not read in a transaction.
  Future<List<Bookmark>> _ayahRows(AyahRef ref, int? wirdId) =>
      (_db.select(_db.bookmarks)
            ..where(
              (b) =>
                  b.surah.equals(ref.surah) &
                  b.ayah.equals(ref.ayah) &
                  (wirdId == null
                      ? b.wirdId.isNull()
                      : b.wirdId.equals(wirdId)),
            )
            ..orderBy([
              (b) => OrderingTerm.desc(b.createdAt),
              (b) => OrderingTerm.desc(b.id),
            ]))
          .get();

  /// The ayah bookmarks of [ref] in the scope [wirdId] (null = the general ones), newest first: whether the ayah sheet
  /// says «remove» and what note it shows.
  Future<List<Bookmark>> ayahBookmarkRows(AyahRef ref, {int? wirdId}) =>
      _ayahRows(ref, wirdId);

  Future<int> _insertAyah(AyahRef ref, int page, int? wirdId, String? note) =>
      _db
          .into(_db.bookmarks)
          .insert(
            BookmarksCompanion.insert(
              page: page,
              wirdId: Value(wirdId),
              note: Value(note),
              surah: Value(ref.surah),
              ayah: Value(ref.ayah),
            ),
          );

  Future<void> _deleteIds(Iterable<int> ids) =>
      (_db.delete(_db.bookmarks)..where((b) => b.id.isIn(ids))).go();

  /// One tap on the ayah sheet's bookmark row (feature 013): in one transaction, an ayah with no bookmark of the scope
  /// [wirdId] gets one with no note on [page] (the page where the ayah begins, which the caller takes from the fixed
  /// edition); an ayah that has some loses all of them, notes included. Never touches a page bookmark or another
  /// scope's. Decided from the database. [ArgumentError] when [page] is not 1..604.
  Future<AyahBookmarkChange> toggleAyahBookmark(
    AyahRef ref, {
    required int page,
    int? wirdId,
  }) async {
    _checkPage(page);
    return _db.transaction(() async {
      final rows = await _ayahRows(ref, wirdId);
      if (rows.isEmpty) {
        final id = await _insertAyah(ref, page, wirdId, null);
        return AyahBookmarkChange(
          kind: AyahChangeKind.added,
          ref: ref,
          page: page,
          addedId: id,
        );
      }
      await _deleteIds([for (final r in rows) r.id]);
      return AyahBookmarkChange(
        kind: AyahChangeKind.removed,
        ref: ref,
        page: page,
        removed: rows,
      );
    });
  }

  /// One save of the note field «ملاحظة للآية» (spec FR-021, data-model.md "the four saves"), in one transaction and
  /// decided from the database. [note] is trimmed; spaces only is empty. No bookmark and a note: one is created with it
  /// (createdWithNote). Bookmarks and a note: the note of every row of the scope is replaced, nothing else changes
  /// (noteReplaced). Bookmarks and no note: their notes are cleared, the bookmarks stay (noteCleared). No bookmark and no
  /// note: nothing is written and the answer is null. [ArgumentError] when [page] is not 1..604.
  Future<AyahBookmarkChange?> saveAyahNote(
    AyahRef ref, {
    required int page,
    int? wirdId,
    String? note,
  }) async {
    _checkPage(page);
    final text = note?.trim() ?? '';
    final value = text.isEmpty ? null : text;
    return _db.transaction(() async {
      final rows = await _ayahRows(ref, wirdId);
      if (rows.isEmpty) {
        if (value == null) return null;
        final id = await _insertAyah(ref, page, wirdId, value);
        return AyahBookmarkChange(
          kind: AyahChangeKind.createdWithNote,
          ref: ref,
          page: page,
          addedId: id,
        );
      }
      await (_db.update(_db.bookmarks)
            ..where((b) => b.id.isIn([for (final r in rows) r.id])))
          .write(BookmarksCompanion(note: Value(value)));
      return AyahBookmarkChange(
        kind: value == null
            ? AyahChangeKind.noteCleared
            : AyahChangeKind.noteReplaced,
        ref: ref,
        page: page,
        before: [for (final r in rows) (id: r.id, note: r.note)],
      );
    });
  }

  /// «تراجع» after [change]: exactly the state before it. The row it added is deleted; the rows it removed come back with
  /// their id, time, note, surah and ayah (one whose wird no longer exists comes back general, as feature 006); the notes
  /// it rewrote are written back by id. Running it twice changes nothing more.
  Future<void> undoAyahBookmarkChange(AyahBookmarkChange change) =>
      _db.transaction(() async {
        switch (change.kind) {
          case AyahChangeKind.added:
          case AyahChangeKind.createdWithNote:
            final id = change.addedId;
            if (id != null) await removeBookmark(id);
          case AyahChangeKind.removed:
            final wirdIds = {
              for (final w in await _db.select(_db.wirds).get()) w.id,
            };
            for (final r in change.removed) {
              await _db
                  .into(_db.bookmarks)
                  .insert(
                    BookmarksCompanion.insert(
                      id: Value(r.id),
                      page: r.page,
                      wirdId: Value(
                        wirdIds.contains(r.wirdId) ? r.wirdId : null,
                      ),
                      note: Value(r.note),
                      createdAt: Value(r.createdAt),
                      surah: Value(r.surah),
                      ayah: Value(r.ayah),
                    ),
                    mode: InsertMode.insertOrIgnore,
                  );
            }
          case AyahChangeKind.noteReplaced:
          case AyahChangeKind.noteCleared:
            for (final b in change.before) {
              await (_db.update(_db.bookmarks)..where((x) => x.id.equals(b.id)))
                  .write(BookmarksCompanion(note: Value(b.note)));
            }
        }
      });

  /// The ayat that have an ayah bookmark in the scope [scopeWirdId] (null = the general ones), from rows already read:
  /// what the reader tints and what the sheet's state is worked out from. Pure.
  Set<AyahRef> ayahMarksOf(Iterable<Bookmark> rows, int? scopeWirdId) => {
    for (final b in rows)
      if (b.surah != null && b.ayah != null && b.wirdId == scopeWirdId)
        AyahRef(b.surah!, b.ayah!),
  };

  /// Every bookmark, newest first, each with its wird's name (null when general).
  Stream<List<BookmarkEntry>> watchBookmarks() {
    final query =
        _db.select(_db.bookmarks).join([
          leftOuterJoin(
            _db.wirds,
            _db.wirds.id.equalsExp(_db.bookmarks.wirdId),
          ),
        ])..orderBy([
          OrderingTerm.desc(_db.bookmarks.createdAt),
          OrderingTerm.desc(_db.bookmarks.id),
        ]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          BookmarkEntry(
            bookmark: r.readTable(_db.bookmarks),
            wirdName: r.readTableOrNull(_db.wirds)?.name,
          ),
      ],
    );
  }

  Future<int> bookmarkCount(int wirdId) async {
    final count = _db.bookmarks.id.count();
    final query = _db.selectOnly(_db.bookmarks)
      ..addColumns([count])
      ..where(_db.bookmarks.wirdId.equals(wirdId));
    return (await query.map((r) => r.read(count)).getSingle()) ?? 0;
  }

  // ------------------------------------------------------------------ reader state and reminders

  Future<int> lastViewedPage() async =>
      int.tryParse(await _getSetting(_kLastViewed) ?? '') ?? 1;

  Future<void> setLastViewedPage(int page) {
    _checkPage(page);
    return _setSetting(_kLastViewed, '$page');
  }

  /// Whether the «ملخص اليوم» card is open over the reader; closed until the user opens it.
  Future<bool> todayPanelExpanded() async =>
      (await _getSetting(_kPanelExpanded)) == 'true';

  Future<void> setTodayPanelExpanded(bool expanded) =>
      _setSetting(_kPanelExpanded, '$expanded');

  /// The stored text size exactly as written, or null if the owner never chose one (feature 003).
  Future<String?> textSizeRaw() => _getSetting(_kTextSize);

  Future<void> setTextSizePercent(int percent) =>
      _setSetting(_kTextSize, '$percent');

  /// The stored look exactly as written (`emerald` or `night`), or null if the owner never chose one (feature 004).
  Future<String?> appLookRaw() => _getSetting(_kAppLook);

  Future<void> setAppLook(String value) => _setSetting(_kAppLook, value);

  /// The stored tint switch of feature 013 exactly as written (`true` or `false`), or null if it was never changed.
  Future<String?> ayahTintRaw() => _getSetting(_kAyahTint);

  Future<void> setAyahTint(bool enabled) => _setSetting(_kAyahTint, '$enabled');

  /// The large-ayah view's four settings exactly as written, or null when never written (feature 015, data-model.md).
  Future<String?> largeAyahRaw() => _getSetting(_kLargeAyah);

  Future<void> setLargeAyah(bool on) => _setSetting(_kLargeAyah, '$on');

  Future<String?> largeAyahCountRaw() => _getSetting(_kLargeAyahCount);

  Future<void> setLargeAyahCount(int count) => _setSetting(_kLargeAyahCount, '$count');

  Future<String?> largeAyahSizeRaw() => _getSetting(_kLargeAyahSize);

  Future<void> setLargeAyahSize(int step) => _setSetting(_kLargeAyahSize, '$step');

  Future<String?> largeAyahAtRaw() => _getSetting(_kLargeAyahAt);

  Future<void> setLargeAyahAt(String key) => _setSetting(_kLargeAyahAt, key);

  /// The stored `prayer.*` keys and their values (feature 014; `PrayerSettings.read` parses them).
  Future<Map<String, String>> prayerEntries() async {
    final rows = await (_db.select(_db.settings)..where((s) => s.key.like('prayer.%'))).get();
    return {for (final r in rows) r.key: r.value};
  }

  /// The `prayer.*` keys, again after every change of them.
  Stream<Map<String, String>> watchPrayerEntries() =>
      (_db.select(_db.settings)..where((s) => s.key.like('prayer.%'))).watch().map(
        (rows) => {for (final r in rows) r.key: r.value},
      );

  /// Writes every `prayer.*` key of [s] in one transaction; a key [s] does not have (no place) is removed.
  Future<void> setPrayerSettings(PrayerSettings s) => _db.transaction(() async {
    final entries = s.toEntries();
    for (final key in kPrayerKeys) {
      final value = entries[key];
      if (value == null) {
        await _removeSetting(key);
      } else {
        await _setSetting(key, value);
      }
    }
  });

  Future<bool> kahfEnabled() async =>
      (await _getSetting(_kKahfEnabled) ?? 'true') == 'true';

  /// The hour of the al-Kahf reminder in minutes after midnight: the one the user chose, else the default of the day
  /// chosen now (21:00 for Thursday, 10:00 for Friday). A default is never stored, so it follows a later change of
  /// day; a chosen hour wins for both days.
  Future<int> kahfMinutes() async => _kahfMinutesFor(await kahfDay());

  Future<int> _kahfMinutesFor(KahfDay day) async =>
      int.tryParse(await _getSetting(_kKahfMinutes) ?? '') ??
      day.defaultMinutes;

  /// Whether the user chose an hour (through [setKahfMinutes] or [setKahf]); the screen needs it to know whether the
  /// shown hour must follow a change of day.
  Future<bool> kahfMinutesChosen() async =>
      int.tryParse(await _getSetting(_kKahfMinutes) ?? '') != null;

  /// The switch alone: stores no hour, so a default still follows the day.
  Future<void> setKahfEnabled(bool enabled) =>
      _setSetting(_kKahfEnabled, '$enabled');

  /// The hour alone, as the user chose it in the picker: it wins over the default of either day from now on.
  Future<void> setKahfMinutes(int minutes) =>
      _setSetting(_kKahfMinutes, '$minutes');

  /// The weekday of the al-Kahf reminder (feature 007): Thursday, the night of Friday, unless Friday was chosen. A
  /// missing setting and a stored text the app does not know both read as Thursday.
  Future<KahfDay> kahfDay() async =>
      KahfDay.fromStorage(await _getSetting(_kKahfDay));

  Future<void> setKahfDay(KahfDay day) =>
      _setSetting(_kKahfDay, day.storageValue);

  Future<void> setKahf({required bool enabled, required int minutes}) =>
      _db.transaction(() async {
        await _setSetting(_kKahfEnabled, '$enabled');
        await _setSetting(_kKahfMinutes, '$minutes');
      });
}

/// Default colour for a new wird (palette entry [index], wrapping).
int wirdColorAt(int index) => wirdPalette[index % wirdPalette.length];
