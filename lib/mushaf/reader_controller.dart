import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ayah/ayah_ref.dart';
import '../wirds/ayah_bookmark_change.dart';
import '../wirds/wird_repository.dart';
import 'models.dart';

/// Holds what the reader shows and applies the position rules (spec FR-015..FR-020):
/// swiping inside the active wird moves it, a jump enters browse mode and moves nothing, and
/// «اجعلها موضعي» moves the wird to the shown page.
class ReaderController extends ChangeNotifier {
  ReaderController(this._repo);

  final WirdRepository _repo;
  StreamSubscription<List<Wird>>? _subscription;
  List<Bookmark> _bookmarks = const [];
  final ValueNotifier<bool> _pageBookmarked = ValueNotifier<bool>(false);
  final ValueNotifier<Set<AyahRef>> _ayahMarks = ValueNotifier<Set<AyahRef>>(
    const {},
  );
  MushafMeta? _meta;
  bool _toggleBusy = false;
  Wird? _wird;
  int _page = 1;
  bool _browsing = true;
  bool _disposed = false;

  /// The page being shown (1..604).
  int get page => _page;

  /// The active wird, or null when no wird exists.
  Wird? get wird => _wird;

  /// True after a jump, or when there is no wird: paging then moves no wird.
  bool get browsing => _browsing;

  /// True while the page shown has a bookmark of the current scope: the active wird's when following a wird, the
  /// general ones when browsing or with no wird (feature 006, data-model.md «Scope»). Changing it does not notify
  /// this controller's listeners, so only the icon that listens to it rebuilds, never the Mushaf page.
  ValueListenable<bool> get pageBookmarked => _pageBookmarked;

  /// The ayat that have an ayah bookmark of the current scope (feature 013, data-model.md Controller state): what the Mushaf
  /// pages tint. Empty until the first read answers; replaced only when the set really changes, and changing it does not
  /// notify this controller's listeners, so only the pages whose words it changes rebuild.
  ValueListenable<Set<AyahRef>> get ayahMarks => _ayahMarks;

  /// The fixed edition's data, for the page where an ayah begins (`pageOfAyah`); the reader hands it over at start so the
  /// controller itself loads no asset.
  void attachMeta(MushafMeta meta) => _meta = meta;

  /// The wird whose bookmarks a tap on the icon reads and writes; null means the general ones.
  int? get _scopeWirdId {
    final wird = _wird;
    return _browsing || wird == null ? null : wird.id;
  }

  static void _check(int page) {
    if (page < 1 || page > 604) {
      throw ArgumentError.value(page, 'page', 'must be between 1 and 604');
    }
  }

  /// Opens on the active wird's position; with no wird, browse mode on the last viewed page.
  Future<void> init() async {
    await _loadPosition();
    _subscription = _repo.watchWirds().listen(_onWirdsChanged);
    await refreshBookmarks();
    _notify();
  }

  /// Reads the position again from the database, as after a backup was restored.
  Future<void> reload() async {
    await _loadPosition();
    await refreshBookmarks();
    _notify();
  }

  Future<void> _loadPosition() async {
    final active = await _repo.activeWird();
    _wird = active;
    if (active != null) {
      _page = active.currentPage;
      _browsing = false;
    } else {
      _page = await _repo.lastViewedPage();
      _browsing = true;
    }
  }

  /// The page changed because the user swiped (or the pager settled on it).
  Future<void> onPageShown(int page) async {
    _check(page);
    _page = page;
    _notify();
    final wird = _wird;
    if (!_browsing && wird != null) await _repo.setPage(wird.id, page);
    await _repo.setLastViewedPage(page);
  }

  /// A jump from the index, a bookmark or a notification: browse mode, no wird moves.
  Future<void> jumpTo(int page) async {
    _check(page);
    _page = page;
    _browsing = true;
    _notify();
    await _repo.setLastViewedPage(page);
  }

  /// «اجعلها موضعي»: the active wird's position becomes the shown page.
  Future<void> makeThisMyPosition() async {
    final wird = _wird;
    if (wird == null) return;
    await _repo.setPage(wird.id, _page);
    _browsing = false;
    _notify();
  }

  /// Makes [wirdId] the active wird and shows its position.
  Future<void> switchWird(int wirdId) async {
    await _repo.setActive(wirdId);
    final wird = await _repo.wirdById(wirdId);
    _wird = wird;
    if (wird != null) {
      _page = wird.currentPage;
      _browsing = false;
    }
    _notify();
  }

  /// Bookmarks the page being shown. Outside browse mode it belongs to the active wird; in browse
  /// mode, or with no wird, it is general («عامة») (spec FR-033).
  Future<void> addBookmark({String? note}) async {
    final wird = _wird;
    await _repo.addBookmark(
      _page,
      note,
      wirdId: _browsing || wird == null ? null : wird.id,
    );
    await refreshBookmarks();
  }

  /// One tap on the bookmark icon (feature 006): adds a bookmark on the page shown when the current scope has none,
  /// otherwise removes the scope's bookmarks. Returns null, and writes nothing, while the previous tap is still being
  /// written, so a double tap cannot add twice. The icon changes only when the database says so.
  Future<BookmarkToggle?> toggleBookmark() async {
    if (_toggleBusy) return null;
    _toggleBusy = true;
    try {
      final result = await _repo.toggleBookmark(_page, wirdId: _scopeWirdId);
      await refreshBookmarks();
      return result;
    } finally {
      _toggleBusy = false;
    }
  }

  /// «تراجع» after a tap on the bookmark icon.
  Future<void> undoBookmarkToggle(BookmarkToggle toggle) async {
    await _repo.undoBookmarkToggle(toggle);
    await refreshBookmarks();
  }

  /// Whether [ref] has an ayah bookmark of the current scope and its note (the first one that has a note), answered from
  /// the rows already in memory so the ayah sheet is right in its first frame (research D5, D8).
  ({bool bookmarked, String? note}) ayahState(AyahRef ref) {
    final scope = _scopeWirdId;
    final rows = [
      for (final b in _bookmarks)
        if (b.surah == ref.surah && b.ayah == ref.ayah && b.wirdId == scope) b,
    ];
    return (
      bookmarked: rows.isNotEmpty,
      note: rows.map((b) => b.note).nonNulls.firstOrNull,
    );
  }

  int _pageOfAyah(AyahRef ref) {
    final meta = _meta;
    if (meta == null) throw StateError('attachMeta was not called');
    return meta.pageOfAyah(ref.surah, ref.ayah);
  }

  /// Runs [write] unless another bookmark write is in progress (then null and nothing is written), and reads the
  /// bookmarks again after it.
  Future<T?> _guarded<T>(Future<T> Function() write) async {
    if (_toggleBusy) return null;
    _toggleBusy = true;
    try {
      final result = await write();
      await refreshBookmarks();
      return result;
    } finally {
      _toggleBusy = false;
    }
  }

  /// One tap on the ayah sheet's bookmark row (feature 013): adds a bookmark on [ref] with no note when the scope has none,
  /// otherwise removes the scope's. The page stored is where the ayah begins. Null while another write is in progress.
  Future<AyahBookmarkChange?> toggleAyahBookmark(AyahRef ref) => _guarded(
    () => _repo.toggleAyahBookmark(
      ref,
      page: _pageOfAyah(ref),
      wirdId: _scopeWirdId,
    ),
  );

  /// One save of «ملاحظة للآية» (spec FR-021). Null while another write is in progress, and for an empty note on an ayah
  /// with no bookmark (nothing is written).
  Future<AyahBookmarkChange?> saveAyahNote(AyahRef ref, String? note) =>
      _guarded<AyahBookmarkChange?>(
        () => _repo.saveAyahNote(
          ref,
          page: _pageOfAyah(ref),
          wirdId: _scopeWirdId,
          note: note,
        ),
      );

  /// «تراجع» after a tap of the bookmark row or a save of the note.
  Future<void> undoAyahBookmarkChange(AyahBookmarkChange change) async {
    await _repo.undoAyahBookmarkChange(change);
    await refreshBookmarks();
  }

  /// Reads the bookmarks again and recomputes [pageBookmarked]. Called after every change the controller makes, after
  /// the «علامات» sheet closes (its swipe-to-delete writes straight to the repository) and when the active wird is
  /// replaced. It is a one-shot read on purpose: the controller holds no bookmark stream, so a bookmark written by
  /// anyone else never waits on this controller's zone (research D2).
  Future<void> refreshBookmarks() async {
    final rows = await _repo.bookmarkRows();
    if (_disposed) return;
    _bookmarks = rows;
    _updatePageBookmarked();
  }

  void _updatePageBookmarked() {
    if (_disposed) return;
    final scope = _scopeWirdId;
    _pageBookmarked.value = _bookmarks.any(
      (b) => b.page == _page && b.wirdId == scope && b.surah == null,
    );
    final marks = _repo.ayahMarksOf(_bookmarks, scope);
    if (!setEquals(marks, _ayahMarks.value)) _ayahMarks.value = marks;
  }

  /// Opens what a tapped notification points at (contracts/notifications.md): `wird:<id>` shows that
  /// wird at its position (browse mode at the last viewed page if it no longer exists), `page:<n>`
  /// shows page n in browse mode. Anything else is ignored.
  Future<void> openPayload(String payload) async {
    final parts = payload.split(':');
    if (parts.length != 2) return;
    final n = int.tryParse(parts[1]);
    if (n == null) return;
    switch (parts[0]) {
      case 'wird':
        if (await _repo.wirdById(n) != null) {
          await switchWird(n);
        } else {
          await jumpTo(await _repo.lastViewedPage());
        }
      case 'page':
        if (n >= 1 && n <= 604) await jumpTo(n);
    }
  }

  /// Keeps [wird] fresh and reacts to the active wird being deleted.
  Future<void> _onWirdsChanged(List<Wird> _) async {
    final active = await _repo.activeWird();
    if (_disposed) return;
    final previous = _wird;
    var replaced = false;
    if (active == null) {
      if (previous != null) {
        _wird = null;
        _browsing = true;
        _page = await _repo.lastViewedPage();
        replaced = true;
      }
    } else if (previous?.id != active.id) {
      _wird = active;
      _page = active.currentPage;
      _browsing = false;
      replaced = true;
    } else {
      _wird = active;
    }
    // A deleted wird's bookmarks became general in the database: read them again.
    if (replaced) await refreshBookmarks();
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    _updatePageBookmarked();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _pageBookmarked.dispose();
    _ayahMarks.dispose();
    super.dispose();
  }
}
