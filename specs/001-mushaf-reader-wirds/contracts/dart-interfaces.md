# Contract: Dart module interfaces

Interfaces that later features (audio, hifz/review, tests) build on. Full per-task detail:
`docs/superpowers/plans/2026-11-20-plan-1-mushaf-and-wirds.md`.

## mushaf/

```dart
class SurahInfo { int number; String name; int ayahs; int startPage; }
class MushafWord { int id; String key; String glyph; int surah; int ayah; }
enum LineType { ayah, surahName, basmallah }
class MushafLine { int number; LineType type; bool centered; int? surah; List<MushafWord> words; }
class PageData { int page; int juz; int hizbQuarter; List<MushafLine> lines; }

class MushafMeta {
  List<SurahInfo> surahs;
  int juzOf(int page); int hizbQuarterOf(int page); List<int> surahsOn(int page);
  int pageOfAyah(int surah, int ayah); SurahInfo surah(int n);
}

class MushafRepository {            // RangeError outside 1..604; caches last 8 pages
  MushafRepository(AssetBundle bundle);
  Future<MushafMeta> loadMeta();
  Future<PageData> loadPage(int page);
}

class PageFontLoader {              // family 'qpc_p$page'
  Future<String> ensure(int page); bool isLoaded(int page); void prefetch(int page);
}

class MushafPage extends StatelessWidget {   // each word keyed ValueKey('w<id>')
  MushafPage({required PageData data, required MushafMeta meta, required String fontFamily,
    Set<int> highlightedWordIds = const {}, Set<int> hiddenWordIds = const {},
    void Function(MushafWord)? onWordTap, void Function(MushafWord)? onWordLongPress});
}

class ReaderController extends ChangeNotifier {
  int get page; Wird? get wird; bool get browsing;
  Future<void> init(); Future<void> onPageShown(int page); Future<void> jumpTo(int page);
  Future<void> makeThisMyPosition(); Future<void> switchWird(int wirdId);
}
```

## wirds/

```dart
enum WirdType { reading, hifz, review, qiyam }
class WirdDraft { String name; WirdType type; int startPage; int? dailyPages; DateTime? targetDate;
  bool notifyEnabled; int? notifyMinutes; int color; }

class WirdRepository {
  Future<void> ensureDefaults();                 // idempotent
  Stream<List<Wird>> watchWirds(); Future<Wird?> activeWird(); Future<void> setActive(int id);
  Future<int> create(WirdDraft d); Future<void> update(int id, WirdDraft d); Future<void> delete(int id);
  Future<void> setPage(int wirdId, int page);    // ArgumentError outside 1..604
  Future<WirdDay> today(int wirdId, DateTime now); Future<void> markDone(int wirdId, DateTime now);
  Future<int> lastViewedPage(); Future<void> setLastViewedPage(int page);
  // bookmarks: add / remove / watch; settings: kahfEnabled, kahfMinutes getters/setters
}

// portion.dart (pure)
String dayKey(DateTime localNow);
String wirdDayKey(WirdType type, DateTime localNow);   // qiyam: day starts at 04:00
int pagesPerDay({required int currentPage, int? dailyPages, DateTime? targetDate, required DateTime today});
({int start, int end}) portionFor({required int startPage, required int perDay});
bool isDone(WirdDay d, int currentPage);
({int nextPage, bool completedKhatma}) afterDone(int endPage);
```

## reminders/ and backup/

```dart
class PlannedReminder { int id; DateTime at; String title; String body; String payload; }
List<PlannedReminder> planReminders({required List<Wird> wirds, required Map<int, bool> doneToday,
  required bool kahfEnabled, required int kahfMinutes, required int kahfPage,
  required DateTime now, int horizonDays = 14});

class ReminderService { Future<void> init(void Function(String payload) onTap);
  Future<bool> requestPermission(); Future<void> reschedule(List<PlannedReminder> plan); }

class BackupService { Future<String> exportJson(); Future<void> importJson(String json); }
```
