# Contract: Dart interfaces (what the UI and the tests depend on)

Signatures are the contract, not the code. All pure logic below has no `dart:ui` or widget import, so it is
unit-tested directly (Constitution IX). Services are provided in `lib/app.dart` and replaced by fakes in tests
(`test/support/`), like `Backup` and `BackupFiles`.

## Pure logic (`lib/ayah/`)

```dart
class AyahRef { const AyahRef(int surah, int ayah); String get key; /* value equality */ }

AyahRef ayahOfWord(MushafWord w);
/// Ids of every word (marker included) of [ref] that is on [page]; empty if the ayah is not on it.
Set<int> wordIdsOfAyah(PageData page, AyahRef ref);

class ShareTextBuilder {
  const ShareTextBuilder(this.meta);               // for surah names
  String ayah(AyahRef ref, List<String> words);    // ﴿ … ﴾ \n [سورة …: n]
  String tafsir(AyahRef ref, String text);         // text \n\n [ref] \n تفسير السعدي
  String translation(AyahRef ref, String text);    // text \n\n [ref] \n Saheeh International
}

class FileNames { static String page(int page); static String surah(String name); }
class SurahPages { const SurahPages(this.first, this.last); factory SurahPages.of(MushafMeta m, int surah); int get count; }
```

## Data (`lib/ayah/ayah_repository.dart`)

```dart
class AyahRepository {
  AyahRepository(AssetBundle bundle);
  Future<List<String>> words(AyahRef ref);               // Quran words, unchanged
  Future<TafsirResult> tafsir(AyahRef ref);              // entry + inherited flag; never "not found" for a valid ref
  Future<String> translation(AyahRef ref);
  Future<List<GharibEntry>> gharib(AyahRef ref);         // empty list = no difficult words
  Future<List<Source>> sources();                        // labels and About credits
}
```
A lookup loads one surah file of one kind, keeps the last 3 per kind, decodes files over ~50 KB with `compute`,
throws `StateError` with the asset name if a file is missing or malformed (a build bug, caught by tests).

## Sharing (`lib/ayah/share_service.dart`)

```dart
enum ShareOutcome { shared, dismissed }
enum ShareFailureKind { noSpace, couldNotPrepare, couldNotShare }
class ShareFailure implements Exception { final ShareFailureKind kind; String get message; /* Arabic */ }

abstract interface class ShareService {
  Future<ShareOutcome> shareText(String text);
  Future<ShareOutcome> shareFile({required String path, required String fileName, required String mimeType});
  // throws ShareFailure(couldNotShare) when the platform call fails
}
class TempShareFiles { Future<File> create(String fileName); Future<void> clean(); }
```
`PlatformShareService` wraps `SharePlus.instance.share(ShareParams(...))`; a result of `dismissed` is
`ShareOutcome.dismissed` and never an error.

## Rendering (`lib/render/`)

```dart
abstract interface class PageRenderer {
  Future<Uint8List> picture(int page);                   // PNG, screen look, 2000×3000
  Future<IndexedPage> pdfPage(int page);                 // the app's look, 1600×2400, 256-colour palette + indices, Flate
}
class IndexedPage { final int width, height; final Uint8List palette /* 256 × RGB */, flateBytes; }
```
`OffscreenPageRenderer(MushafRepository, PageFontLoader, MushafMeta)` loads the page data and font, paints
`MushafPageCard`, reads RGBA, reduces it to a 256-colour palette and deflates in `Isolate.run`. Throws `ShareFailure(couldNotPrepare)`
on any render failure. Tests use a fake that returns a tiny image.

## PDF (`lib/pdf/`)

```dart
class A4Layout { static const double width = 595.28, height = 841.89, margin = 28.35;
                 static ({double x, double y, double w, double h}) place(int imageW, int imageH); }

class PdfWriter {                                        // streaming, pure Dart + dart:io RandomAccessFile
  PdfWriter(File file, {required String title, required int pageCount});
  Future<void> addPage(IndexedPage page);                   // call exactly pageCount times
  Future<void> finish();                                 // xref + trailer
  Future<void> abort();                                  // closes and deletes the file
}

class CancelToken { bool get cancelled; void cancel(); }

sealed class PdfJobState { PdfIdle | PdfPreparing(surahName, done, total) | PdfReady(surahName, path, fileName) | PdfFailed(kind) }
class PdfJob extends ChangeNotifier {
  PdfJob({required PageRenderer renderer, required TempShareFiles files, required MushafMeta meta});
  PdfJobState get state;
  bool start(int surah);                                 // false only while a job is preparing; a ready/failed one is replaced
  Future<void> cancel();                                 // idle at once; completes when the partial file is deleted
  Future<void> shareReady(ShareService share);           // ready → idle after the share call returns
  void dismiss();                                        // failed/ready → idle (file removed unless being shared)
}
```
`start` computes `SurahPages`, renders and writes page by page, notifies after every page, checks the token
before and after every await, and ends in `ready` or `failed`.

## Reader wiring (`lib/mushaf/`)

- `MushafPageCard({required PageData data, required MushafMeta meta, required String fontFamily, PageLook look, Set<int> highlightedWordIds, void Function(MushafWord)? onWordLongPress})` — the code now in `_PageItem`, with no behaviour change for `PageLook.screen`.
- `_PageItem` gains `highlightedWordIds` and `onWordLongPress`; `ReaderScreen` owns `Set<int> _highlight`, opens `AyahSheet`
  with `showModalBottomSheet`, clears `_highlight` when it closes, and shows `PdfProgressStrip` from `PdfJob`.
