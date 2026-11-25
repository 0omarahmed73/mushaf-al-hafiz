import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, setEquals;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../ayah/ayah_bookmark_port.dart';
import '../ayah/ayah_ref.dart';
import '../ayah/ayah_repository.dart';
import '../ayah/share_service.dart';
import '../ayah/ui/ayah_sheet.dart';
import '../ayah/ui/pdf_progress_strip.dart';
import '../khatm/khatm_dua_screen.dart';
import '../khatm/last_page_swipe.dart';
import '../large_ayah/large_ayah_pager.dart';
import '../large_ayah/large_ayah_settings.dart';
import '../large_ayah/large_ayah_strings.dart';
import '../large_ayah/page_screens.dart';
import '../large_ayah/screen_layout.dart';
import '../large_ayah/word_measurer.dart';
import '../look/look_settings.dart';
import '../motion/fade_in_on_change.dart';
import '../motion/fade_slide_switcher.dart';
import '../motion/frame_trace.dart';
import '../motion/jump_fade.dart';
import '../motion/motion.dart';
import '../pdf/pdf_job.dart';
import '../reminders/reminder_scheduler.dart';
import '../search/ayah_target.dart';
import '../settings/ayah_tint_settings.dart';
import '../settings/settings_screen.dart';
import '../wirds/ayah_bookmark_change.dart';
import '../wirds/bookmarks_sheet.dart';
import '../wirds/portion.dart';
import '../wirds/today_panel.dart';
import '../wirds/wird_repository.dart';
import '../wirds/wirds_screen.dart';
import 'ayah_bookmark_strings.dart';
import 'ayah_tint.dart';
import 'bookmark_button.dart';
import 'bookmark_strings.dart';
import 'go_to_page_dialog.dart';
import 'index_screen.dart';
import 'models.dart';
import 'mushaf_page_card.dart';
import 'mushaf_repository.dart';
import 'page_font_loader.dart';
import 'page_look.dart';
import '../theme.dart';
import 'page_scale.dart';
import 'page_viewport.dart';
import 'reader_controller.dart';
import '../settings/text_size_settings.dart';

const double _topBarHeight = 84;
const double _bottomBarHeight = 68;

/// The home screen: the Mushaf page of the active wird, with a top bar, a bottom bar, pinch zoom
/// and the position rules. Nothing comes before it (Constitution II).
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  late final WirdRepository _repo;
  late final Reminders? _reminders;
  late final ReaderController _controller;
  late final MushafRepository _mushaf;
  late final PageFontLoader _fonts;
  PdfJob? _pdf;
  PageController? _pages;
  MushafMeta? _meta;
  // Bars are shown in both orientations (landscape used to start hidden; the owner asked to see the surah, juz and page
  // details there too, 2026-11-21); a tap flips the setting of the orientation being used.
  bool _barsPortrait = true;
  bool _barsLandscape = true;
  // Pages whose pager must stay still because the page is wider than the screen or zoomed in; each shown page
  // reports its own state (PageViewport), so a page that comes in during a swipe never inherits another's.
  final Map<int, bool> _locks = {};
  // Feature 005: the forward swipe at page 604 opens the khatm dua; one screen at a time.
  final LastPageSwipe _lastSwipe = LastPageSwipe();
  bool _duaOpen = false;
  Set<int> _highlight = const {};
  int? _highlightPage;
  // The ayah the search found, highlighted through the two fields above until the next touch, turn or opened screen (feature
  // 011, spec FR-013; research D4). Null when none: the long press's own highlight is not this.
  AyahTarget? _found;
  // What the found ayah asks of its page's PageViewport: bring these words into view, once per token (T043). Null with no found ayah.
  PageReveal? _reveal;
  int _revealToken = 0;
  bool _menuOpen = false;
  List<TodayEntry> _today = const [];
  bool _panelOpen = false;
  StreamSubscription<List<TodayEntry>>? _todaySub;
  Timer? _dayBoundary;
  StreamSubscription<String>? _tapSub;
  // The large-ayah view (feature 015): its settings, whether it replaces the Mushaf pager now, where its pager opens (a
  // new token re-anchors it), and the page of the screen it showed last (a page change from elsewhere re-anchors it).
  LargeAyahSettings? _large;
  bool _largeOn = false;
  late final WordMeasurer _measurer;
  LargeTarget _largeTarget = const LargeTarget.page(1);
  int _largeToken = 0;
  int? _largeShownPage;

  @override
  void initState() {
    super.initState();
    _repo = context.read<WirdRepository>();
    _reminders = context.read<Reminders?>();
    _controller = ReaderController(_repo);
    _mushaf = context.read<MushafRepository>();
    _fonts = PageFontLoader();
    _measurer = WordMeasurer(_fonts);
    _large = context.read<LargeAyahSettings?>()?..addListener(_onLargeChanged);
    _pdf = context.read<PdfJob?>()?..addListener(_onPdfChanged);
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    final meta = await _mushaf.loadMeta();
    _controller.attachMeta(meta);
    await _controller.init();
    // A notification that started the app decides where the reader opens.
    final launchedBy = _reminders?.taps.takePending();
    if (launchedBy != null) await _controller.openPayload(launchedBy);
    final panelOpen = await _repo.todayPanelExpanded();
    if (!mounted) return;
    _panelOpen = panelOpen;
    _tapSub = _reminders?.taps.stream.listen(_onNotificationTap);
    _watchToday();
    _pages = PageController(initialPage: _controller.page - 1);
    _controller.addListener(_onController);
    _fonts.prefetch(_controller.page);
    _shown = _controller.page;
    _largeOn = _large?.on ?? false;
    if (_largeOn) _largeTarget = _largeStart(meta);
    setState(() => _meta = meta);
    unawaited(_warmAround());
  }

  @override
  void dispose() {
    _pdf?.removeListener(_onPdfChanged);
    _large?.removeListener(_onLargeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _todaySub?.cancel();
    _dayBoundary?.cancel();
    _barsGone?.cancel();
    _tapSub?.cancel();
    _controller.removeListener(_onController);
    _controller.dispose();
    _pages?.dispose();
    _jump.dispose();
    super.dispose();
  }

  /// Follows today's portions: again whenever a wird or a portion changes, when the app returns to
  /// the front, and when a wird day ends (midnight, or 04:00 for qiyam wirds), so a new day's portion
  /// appears whether the app was open or closed (spec FR-029).
  void _watchToday() {
    _todaySub?.cancel();
    _todaySub = _repo.watchTodayEntries().listen((e) {
      if (mounted) setState(() => _today = e);
    });
    _dayBoundary?.cancel();
    final now = DateTime.now();
    _dayBoundary = Timer(
      nextWirdDayBoundary(now).difference(now) + const Duration(seconds: 1),
      _watchToday,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _meta != null) {
      _watchToday();
      // Repairs a schedule the phone dropped and starts the next day's reminders.
      _reminders?.scheduler.refresh(force: true);
    }
  }

  /// A surah PDF that is ready while the app is in front goes straight to the share sheet; if the app was in
  /// the background the strip waits with «مشاركة» (spec FR-016, contracts/ui.md).
  void _onPdfChanged() {
    final job = _pdf;
    if (job == null || !mounted || job.state is! PdfReady) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final inFront = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final share = context.read<ShareService?>();
    if (inFront && share != null) unawaited(job.shareReady(share));
  }

  /// A notification was tapped while the app was open: show what it points at.
  Future<void> _onNotificationTap(String payload) async {
    _reminders?.taps.takePending();
    Navigator.of(context).popUntil((route) => route.isFirst);
    await _controller.openPayload(payload);
  }

  /// The bookmark icon: one tap adds a bookmark on the page shown, or removes the scope's (feature 006).
  ///
  /// A short floating message follows (above the bottom bar so it never covers it) with «تراجع», which undoes exactly
  /// this tap while the message is shown; the next tap replaces it. A failed write shows nothing and the icon keeps
  /// the state the table really has.
  Future<void> _toggleBookmark() async {
    final BookmarkToggle? result;
    try {
      result = await _controller.toggleBookmark();
    } catch (error) {
      debugPrint('bookmark toggle failed: $error');
      return;
    }
    if (result == null || !mounted) return;
    final toggle = result;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          // A message with an action stays until dismissed by default; this one goes by itself after the usual 4 s.
          persist: false,
          margin: EdgeInsets.fromLTRB(
            12,
            0,
            12,
            (_barsVisible ? _bottomBarHeight : 0) + 8,
          ),
          content: Text(
            toggle.wasAdded
                ? kBookmarkAdded(toggle.page)
                : kBookmarkRemoved(toggle.page),
          ),
          action: SnackBarAction(
            label: kBookmarkUndo,
            onPressed: () => _controller.undoBookmarkToggle(toggle),
          ),
        ),
      );
  }

  /// What the ayah sheet's bookmark and note rows read and write (feature 013): the controller's in-memory state and its
  /// writes, and the message below.
  late final AyahBookmarkPort _ayahBookmarks = AyahBookmarkPort(
    state: _controller.ayahState,
    toggle: _controller.toggleAyahBookmark,
    saveNote: _controller.saveAyahNote,
    onChange: _showAyahBookmarkMessage,
  );

  /// The message after a tap of the ayah sheet's bookmark row or a save of its note (feature 013, contracts/ui.md §3): the
  /// same floating message as the page icon's, above the bottom bar, with «تراجع», which undoes exactly that change while
  /// the message is shown; the next message replaces it.
  void _showAyahBookmarkMessage(AyahBookmarkChange change) {
    final meta = _meta;
    if (!mounted || meta == null) return;
    final name = meta.surah(change.ref.surah).name;
    final ayah = change.ref.ayah;
    final text = switch (change.kind) {
      AyahChangeKind.added => kAyahBookmarkAdded(name, ayah),
      AyahChangeKind.removed => kAyahBookmarkRemoved(name, ayah),
      AyahChangeKind.createdWithNote => kAyahNoteCreated(name, ayah),
      AyahChangeKind.noteReplaced => kAyahNoteSaved(name, ayah),
      AyahChangeKind.noteCleared => kAyahNoteRemoved(name, ayah),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          persist: false,
          margin: EdgeInsets.fromLTRB(
            12,
            0,
            12,
            (_barsVisible ? _bottomBarHeight : 0) + 8,
          ),
          content: Text(text),
          action: SnackBarAction(
            label: kBookmarkUndo,
            onPressed: () => _controller.undoAyahBookmarkChange(change),
          ),
        ),
      );
  }

  /// «علامات»: the bookmarks sheet; tapping a bookmark there opens its page in browse mode, and an ayah bookmark (feature
  /// 013) hands back an [AyahTarget] that is shown as a search result is: its page, its words highlighted and in view.
  Future<void> _openBookmarks() async {
    _clearFound();
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.look.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookmarksSheet(
        page: _controller.page,
        ownerName: _controller.browsing ? null : _controller.wird?.name,
        onAdd: (note) => _controller.addBookmark(note: note),
        meta: _meta,
      ),
    );
    // The sheet may have added or deleted bookmarks directly: the icon reads the table again once it is closed.
    await _controller.refreshBookmarks();
    switch (result) {
      case final int page:
        await _controller.jumpTo(page);
      case final AyahTarget target:
        await _showFoundAyah(target);
    }
  }

  Future<void> _openSettings() async {
    _clearFound();
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const SettingsScreen()),
    );
    if (restored != true || !mounted) return;
    // A backup was restored: show the restored wird and position, and the text size and the tint switch it holds.
    final size = context.read<TextSizeSettings?>();
    final tint = context.read<AyahTintSettings?>();
    await _controller.reload();
    await size?.reload();
    await tint?.reload();
    await _large?.reload();
    if (!mounted) return;
    if (_largeOn) _anchorLargeTo(LargeTarget.page(_controller.page, token: ++_largeToken));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم استرجاع النسخة الاحتياطية')),
    );
  }

  /// Built with `--dart-define=AYAH_MENU_TRACE=true`, a long press logs how long it took from the
  /// press until the menu's first frame was painted: `AYAHMENU ms=<t>` (spec SC-001). Off, and free,
  /// in normal builds.
  static const bool _menuTrace = bool.fromEnvironment('AYAH_MENU_TRACE');

  /// A long press on a word: highlight its ayah on the shown page and open the ayah's menu. The
  /// highlight goes when the menu closes; the page, zoom and position are not touched.
  Future<void> _openAyahMenu(PageData data, MushafWord word) async {
    final meta = _meta;
    if (_menuOpen || meta == null || context.read<AyahRepository?>() == null) {
      return;
    }
    final stopwatch = Stopwatch()..start();
    final ref = ayahOfWord(word);
    HapticFeedback.mediumImpact();
    setState(() {
      _menuOpen = true;
      _found = null; // the menu's own highlight replaces the search's
      _reveal = null;
      _highlightPage = data.page;
      _highlight = wordIdsOfAyah(data, ref);
    });
    if (_menuTrace) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('AYAHMENU ms=${stopwatch.elapsedMilliseconds}');
      });
    }
    await showAyahSheet(
      context,
      ref: ref,
      meta: meta,
      page: data.page,
      bookmarks: _ayahBookmarks,
    );
    if (!mounted) return;
    setState(() {
      _menuOpen = false;
      _highlight = const {};
      _highlightPage = null;
    });
  }

  /// A tap on the page number: ask for a page and show it in browse mode (like a jump from the index).
  Future<void> _askPage() async {
    _clearFound();
    final page = await showDialog<int>(
      context: context,
      builder: (_) => GoToPageDialog(current: _controller.page),
    );
    if (page != null && page != _controller.page) {
      await _controller.jumpTo(page);
    }
  }

  bool get _landscape =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  bool get _barsVisible => _landscape ? _barsLandscape : _barsPortrait;

  /// True from a tap on the page until the next build: only a change of the bars that the reader asked for fades and
  /// slides. A rotation (the other orientation has its own setting) and a resume switch the bars at once, with no
  /// animation (feature 010 T021, spec scenario 5 of US2).
  bool _animateBars = false;

  /// Bars that leave are dropped from the tree by their own fade when it ends (FadeSlideSwitcher). This timer is the
  /// same moment on the clock of the tap itself: it makes the two slots start again empty a little after the fade, so
  /// that a tap followed by one long wait (a test that taps and pumps 300 ms in one frame, the way every earlier reader
  /// test does) finds the bars gone, while the fade is still seen frame by frame when time passes frame by frame.
  /// The 20 ms are a frame and a bit: the fade has ended by then, so nothing visible is cut short.
  Timer? _barsGone;
  int _barsEpoch = 0;

  void _toggleBars() {
    setState(() {
      _animateBars = true;
      if (_landscape) {
        _barsLandscape = !_barsLandscape;
      } else {
        _barsPortrait = !_barsPortrait;
      }
    });
    _barsGone?.cancel();
    if (_barsVisible || Motion.reduced(context)) return;
    _barsGone = Timer(Motion.barOut + const Duration(milliseconds: 20), () {
      if (mounted && !_barsVisible) setState(() => _barsEpoch++);
    });
  }

  void _togglePanel() {
    setState(() => _panelOpen = !_panelOpen);
    _repo.setTodayPanelExpanded(_panelOpen);
  }

  Future<void> _markDone(TodayEntry entry) =>
      _repo.markDone(entry.wird.id, DateTime.now());

  Future<void> _openWirds() async {
    _clearFound();
    final id = await Navigator.of(context)
        .push<int>(MaterialPageRoute(builder: (_) => const WirdsScreen()));
    if (id != null) await _controller.switchWird(id);
  }

  /// The page [page] must keep the pager still (it moves in two directions or is zoomed) or lets it turn pages.
  void _onLockChanged(int page, bool locked) {
    final was = _locks[page] ?? false;
    _locks[page] = locked;
    if (was != locked && page == _controller.page && mounted) setState(() {});
  }

  /// A page left the pager; forget its lock.
  void _onPageGone(int page) => _locks.remove(page);

  /// A swipe from a side edge of a page that is wider than the screen turns the page, with the same slide and
  /// the same position saving as a swipe on the pager (spec FR-008).
  void _onEdgeTurn(PageTurn turn) {
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    final index = (pages.page ?? (_controller.page - 1)).round();
    if (turn == PageTurn.next && index == MushafMeta.pageCount - 1) {
      unawaited(_openDua());
      return;
    }
    final target = switch (turn) {
      PageTurn.next => index + 1,
      PageTurn.previous => index - 1,
      PageTurn.none => index,
    };
    if (target == index || target < 0 || target >= MushafMeta.pageCount) return;
    // Under «remove animations» the scroll animation of animateToPage still takes its 300 ms (the framework shortens only
    // the controllers and transitions it builds itself), so the turn is made in one frame there (feature 010 T040, spec
    // FR-014, research D7).
    if (Motion.reduced(context)) {
      pages.jumpToPage(target);
      return;
    }
    unawaited(
      pages.animateToPage(
        target,
        duration: Motion.edgeTurn,
        curve: Motion.enter,
      ),
    );
  }

  /// What the pager reports while a finger drags past the last page: only there can a forward drag overscroll, so
  /// the rule never fires on pages 1 to 603 and never from a jump (feature 005, research D1). Never consumes.
  bool _onPagerScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.horizontal) return false;
    if (n is ScrollStartNotification) {
      _lastSwipe.start();
      if (FrameTrace.enabled) {
        debugPrint(
          FrameTrace.warmLine(
            next: _isReady(_controller.page + 1),
            prev: _isReady(_controller.page - 1),
          ),
        );
      }
    } else if (n is OverscrollNotification) {
      if (n.overscroll > 0) _lastSwipe.overscroll(n.overscroll);
    } else if (n is ScrollEndNotification) {
      final velocity = n.dragDetails?.velocity.pixelsPerSecond.dx ?? 0;
      if (_lastSwipe.end(velocity: velocity)) unawaited(_openDua());
      // The slide has ended: now the pages around the shown one are asked for.
      unawaited(_warmAround());
    }
    return false;
  }

  /// «دعاء ختم القرآن»: «آمين» shows page 1 by the ordinary page change (so the saved position becomes 1); back
  /// leaves the reader on page 604 as it was.
  Future<void> _openDua() async {
    if (_duaOpen || !mounted) return;
    _duaOpen = true;
    final amen = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const KhatmDuaScreen()));
    _duaOpen = false;
    if (amen == true && mounted) await _controller.onPageShown(1);
  }

  /// The controller changed (a page turn, a jump, a wird switch): move the pager to the page, and make the pager again
  /// only if the shown page has another lock than the one the pager was made with (feature 010 T011).
  void _onController() {
    // A jump, a wird switch or a restored position moved the page away from the large-ayah screen shown: its pager opens
    // that page's first screen. Its own screens move the page too, and then the pages agree.
    final shownLarge = _largeShownPage;
    if (_largeOn && shownLarge != null && shownLarge != _controller.page) {
      _anchorLargeTo(LargeTarget.page(_controller.page, token: ++_largeToken));
    }
    _syncPager();
    if (mounted && _pagerWidget != null && _pageLocked != _pagerLocked) {
      setState(() {});
    }
  }

  /// A jump or a wird switch changed the page: move the pager to it, and let the new page fade in (feature 010 T032: no
  /// slide and no page built in between; a start, a swipe and a jump to the page already shown play nothing).
  void _syncPager() {
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    final shown = pages.page?.round() ?? _controller.page - 1;
    if (shown != _controller.page - 1) {
      pages.jumpToPage(_controller.page - 1);
      _jump.play();
    }
  }

  /// Plays the soft arrival of a page that replaced the shown one by a jump.
  final JumpFadeController _jump = JumpFadeController();

  /// The page the pager showed last and the direction of the last turn (1 towards a higher page): what [_warmAround]
  /// asks for first.
  int _shown = 1;
  int _direction = 1;
  int _warmRun = 0;

  void _onPageChanged(int index) {
    final page = index + 1;
    // A turn or a jump to another page (a notification tap, the bookmarks) ends the found ayah's highlight; its own page
    // arriving is not a turn away from it.
    if (_found != null && page != _highlightPage) _clearFound();
    _direction = page >= _shown ? 1 : -1;
    _shown = page;
    // Nothing is loaded here: this runs in the middle of the slide. The pages around the new one are asked for when
    // the slide has ended (feature 010 T013).
    _controller.onPageShown(page);
  }

  /// Asks for the fonts and then the text of the pages around the shown one, the direction of the turn first, one
  /// step per frame, so no read, parse or font registration lands in a frame of a slide (feature 010 T013). A newer
  /// call replaces an older one.
  Future<void> _warmAround() async {
    final run = ++_warmRun;
    final page = _controller.page;
    final d = _direction;
    Future<bool> nextFrame() async {
      await WidgetsBinding.instance.endOfFrame;
      return mounted && run == _warmRun;
    }

    if (!await nextFrame()) return;
    _fonts.prefetch(page, direction: d);
    for (final p in [page + d, page + 2 * d, page - d, page - 2 * d]) {
      if (!await nextFrame()) return;
      unawaited(_mushaf.prefetch(p));
    }
  }

  bool _isReady(int page) =>
      _mushaf.peek(page) != null && _fonts.isLoaded(page);

  /// The index returns an `int` (a page: a jump, as it always was) or, from the search screen of feature 011, an [AyahTarget].
  Future<void> _openIndex() async {
    _clearFound();
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute<Object>(builder: (_) => const IndexScreen()),
    );
    switch (result) {
      case final int page:
        await _controller.jumpTo(page);
      case final AyahTarget target:
        await _showFoundAyah(target);
    }
  }

  /// An ayah chosen in the search: its page is shown in browse mode, only when it is not the page already shown (then the mode
  /// stays, as after the go-to-page dialog), and its words on that page are highlighted with the long press's highlight (spec
  /// FR-013, FR-015, FR-016; research D4). The words are read before the jump, so the highlight is there in the first frame
  /// the page is drawn in. A new set makes the kept pager again, once.
  Future<void> _showFoundAyah(AyahTarget target) async {
    var ids = const <int>{};
    try {
      ids = wordIdsOfAyah(await _mushaf.loadPage(target.page), target.ref);
    } catch (error) {
      // The page reports its own failure when it is built; the jump below still happens.
      debugPrint('found ayah: page ${target.page} could not be read: $error');
    }
    if (!mounted) return;
    final jump = target.page != _controller.page;
    setState(() {
      _found = target;
      _highlightPage = target.page;
      _highlight = ids;
      // A new token every time: a result on the page already shown brings the ayah into view again.
      _reveal = ids.isEmpty ? null : PageReveal(ids, ++_revealToken);
    });
    if (_largeOn) _anchorLargeTo(LargeTarget.ayah(target.ref, token: ++_largeToken), page: target.page);
    if (jump) await _controller.jumpTo(target.page);
  }

  // ---------------------------------------------------------------- the large-ayah view (feature 015)

  /// Where the view opens at start: the remembered ayah when it is on the position's page, else that page's first screen
  /// (research D6).
  LargeTarget _largeStart(MushafMeta meta) {
    final at = _large?.at;
    if (at != null && meta.pageOfAyah(at.surah, at.ayah) == _controller.page) {
      return LargeTarget.ayah(at, token: ++_largeToken);
    }
    return LargeTarget.page(_controller.page, token: ++_largeToken);
  }

  void _anchorLargeTo(LargeTarget target, {int? page}) {
    _largeShownPage = page ?? target.page;
    setState(() => _largeTarget = target);
  }

  /// The view was turned on or off, or its count or size changed.
  void _onLargeChanged() {
    final on = _large?.on ?? false;
    if (!mounted) return;
    if (on == _largeOn) {
      setState(() {});
      return;
    }
    setState(() {
      _largeOn = on;
      if (on) {
        _clearFound();
        _largeShownPage = null;
        _largeTarget = LargeTarget.page(_controller.page, token: ++_largeToken);
      } else {
        // The Mushaf pager comes back on the page of the last screen shown, with a new controller (the old one had no
        // pager while the view was on).
        final old = _pages;
        _pages = PageController(initialPage: _controller.page - 1);
        _pagerWidget = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
      }
    });
  }

  void _onLargeScreen(LargeScreen screen) {
    if (_found != null && screen.page != _highlightPage) _clearFound();
    _largeShownPage = screen.page;
    unawaited(_large?.setAt(screen.ayat.first));
    if (screen.page != _controller.page) unawaited(_controller.onPageShown(screen.page));
  }

  Future<void> _onLargeLongPress(int page, MushafWord word) async {
    final data = await _mushaf.loadPage(page);
    if (!mounted) return;
    await _openAyahMenu(data, word);
  }

  Widget _largeView(MushafMeta meta) {
    final large = _large!;
    final look = context.watch<AppLookSettings?>()?.pageLook ?? PageLook.screen;
    final tintOn = context.watch<AyahTintSettings?>()?.enabled ?? true;
    return Stack(
      children: [
        Positioned.fill(
          child: LargeAyahPager(
            sourceFor: (g) => PageScreens(mushaf: _mushaf, measurer: _measurer, geometry: g, count: large.count),
            layoutKey: large.count,
            pageOfAyah: (a) => meta.pageOfAyah(a.surah, a.ayah),
            meta: meta,
            factor: large.factor,
            target: _largeTarget,
            look: look,
            highlightedWordIds: _highlight,
            ayahMarks: tintOn ? _controller.ayahMarks : null,
            onScreenShown: _onLargeScreen,
            onWordLongPress: _onLargeLongPress,
            onTap: _toggleBars,
            onPastEnd: () => unawaited(_openDua()),
          ),
        ),
        // «المصحف»: at the end of the screen's header line, which keeps that place free (contracts/ui.md).
        PositionedDirectional(
          top: LargeGeometry.vPad,
          end: LargeGeometry.hPad - 8,
          child: Tooltip(
            message: LargeAyahStrings.backToMushafTooltip,
            child: TextButton.icon(
              key: const ValueKey('large-back'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: look.ink),
              onPressed: () => large.setOn(false),
              icon: const Icon(Icons.menu_book),
              label: const Text(LargeAyahStrings.backToMushaf),
            ),
          ),
        ),
      ],
    );
  }

  /// The next touch, turn or opened screen ends the found ayah's highlight (spec FR-013; research D4). Does nothing, and
  /// rebuilds nothing, when no ayah was found: the long press's own highlight is not touched.
  void _clearFound() {
    if (_found == null) return;
    setState(() {
      _found = null;
      _highlight = const {};
      _highlightPage = null;
      _reveal = null;
    });
  }

  // The pager and the bottom bar are kept as instances (feature 010 T011): the framework skips a widget that is the same
  // instance as last time, so a tap on the page, a database answer or a page turn never rebuilds them. They are made
  // again only when what they show changes (see _pagerFor).
  Widget? _pagerWidget;
  MushafMeta? _pagerMeta;
  bool _pagerLocked = false;
  int? _pagerHighlightPage;
  Set<int>? _pagerHighlight;
  PageReveal? _pagerReveal;

  late final Widget _bottomBar = _BottomBar(
    onWirds: _openWirds,
    onBookmarks: _openBookmarks,
    onSettings: _openSettings,
  );

  /// True while the shown page keeps the pager still (zoomed in, or wider than the screen).
  bool get _pageLocked => _locks[_controller.page] ?? false;

  Widget _pagerFor(MushafMeta meta, PageController pages) {
    final locked = _pageLocked;
    final cached = _pagerWidget;
    if (cached != null &&
        identical(_pagerMeta, meta) &&
        _pagerLocked == locked &&
        _pagerHighlightPage == _highlightPage &&
        identical(_pagerHighlight, _highlight) &&
        identical(_pagerReveal, _reveal)) {
      return cached;
    }
    _pagerMeta = meta;
    _pagerLocked = locked;
    _pagerHighlightPage = _highlightPage;
    _pagerHighlight = _highlight;
    _pagerReveal = _reveal;
    return _pagerWidget = Directionality(
      // LTR + reverse: the next page comes in from the left, like the paper Mushaf.
      textDirection: TextDirection.ltr,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onPagerScroll,
        child: PageView.builder(
          reverse: true,
          controller: pages,
          itemCount: MushafMeta.pageCount,
          // The next and the previous page are built while the pager rests, so the first frames of a swipe build nothing
          // for the incoming page; the one-pixel cache keeps the page after the neighbour for the end of the slide
          // (feature 010 T012, research D2). The neighbours are offstage for finders and not in the semantics tree.
          allowImplicitScrolling: true,
          scrollCacheExtent: const ScrollCacheExtent.pixels(1),
          physics: locked
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleBars,
            child: _PageItem(
              page: index + 1,
              meta: meta,
              mushaf: _mushaf,
              fonts: _fonts,
              highlightedWordIds: _highlightPage == index + 1
                  ? _highlight
                  : const {},
              reveal: _highlightPage == index + 1 ? _reveal : null,
              // The same notifier object every time: the kept pager is never made again for a bookmark (feature 013).
              ayahMarks: _controller.ayahMarks,
              onAyahLongPress: _openAyahMenu,
              onPageNumberTap: _askPage,
              onLockChanged: _onLockChanged,
              onEdgeTurn: _onEdgeTurn,
              onGone: _onPageGone,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final pages = _pages;
    if (meta == null || pages == null) {
      return const Scaffold(body: SizedBox.expand());
    }
    final barsVisible = _barsVisible;
    // Read once and cleared: only the build that follows a tap on the page animates the bars (see _animateBars).
    final animateBars = _animateBars;
    _animateBars = false;
    return Scaffold(
      body: Listener(
        // The found ayah of the search stays highlighted "until the next touch": any pointer-down on the reader (the page, a bar,
        // the today card) ends it. A Listener is not a gesture detector, so it takes no tap from the page or the bars, and it
        // adds no layout (feature 011 T042, research D4).
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _clearFound(),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: _topBarHeight,
                    // Only the top line listens to the reader controller: a page turn, a wird switch or a change of the
                    // bookmark rebuilds it and nothing else (feature 010 T011). The slot keeps its height: the bar fades
                    // and slides inside it, so the page never moves (feature 010 T021).
                    child: FadeSlideSwitcher(
                      key: ValueKey(_barsEpoch),
                      slide: -Motion.barSlide,
                      animate: animateBars,
                      child: barsVisible
                          ? ListenableBuilder(
                              listenable: _controller,
                              builder: (context, _) => _TopBar(
                                meta: meta,
                                page: _controller.page,
                                wirdName: _controller.wird?.name,
                                showBrowseBanner:
                                    _controller.browsing &&
                                    _controller.wird != null,
                                today: _today,
                                todayOpen: _panelOpen,
                                onToggleToday: _togglePanel,
                                onOpenIndex: _openIndex,
                                onOpenWirds: _openWirds,
                                onMakePosition: _controller.makeThisMyPosition,
                                pageBookmarked: _controller.pageBookmarked,
                                onToggleBookmark: _toggleBookmark,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: _largeOn && _large != null
                        ? _largeView(meta)
                        : JumpFade(
                            controller: _jump,
                            child: _pagerFor(meta, _pages!),
                          ),
                  ),
                  SizedBox(
                    height: _bottomBarHeight,
                    child: FadeSlideSwitcher(
                      key: ValueKey(_barsEpoch),
                      slide: Motion.barSlide,
                      animate: animateBars,
                      child: barsVisible ? _bottomBar : null,
                    ),
                  ),
                ],
              ),
              // The surah PDF strip floats above the bottom bar and covers only its own 56 px; pages and bars
              // stay usable under and around it.
              // It moves with the bottom bar's own duration and curve, so it does not jump while the bar slides.
              if (_pdf != null && context.read<ShareService?>() != null)
                AnimatedPositioned(
                  duration: animateBars
                      ? Motion.of(
                          context,
                          barsVisible ? Motion.barIn : Motion.barOut,
                        )
                      : Duration.zero,
                  curve: barsVisible ? Motion.enter : Motion.exit,
                  left: 12,
                  right: 12,
                  bottom: (barsVisible ? _bottomBarHeight : 0) + 8,
                  child: PdfProgressStrip(
                    job: _pdf!,
                    share: context.read<ShareService?>()!,
                  ),
                ),
              // The «ملخص اليوم» card is modal: a tap anywhere outside it closes it, and that tap does
              // nothing else (it does not turn a page or press a bar button).
              // The barrier follows the open state at once; the card itself fades and slides a little (feature 010 T022)
              // and, while it leaves, ignores taps, so a tap on the page reaches the page. The card's slot has a key:
              // the barrier comes and goes before it in this list, and without a key the card's state would be handed to
              // the barrier's slot and lost (its fade would start again from nothing).
              if (_panelOpen && _today.isNotEmpty)
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('today-barrier'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _togglePanel,
                  ),
                ),
              Positioned(
                key: const ValueKey('today-card-slot'),
                top: _topBarHeight + 6,
                left: 16,
                right: 16,
                child: FadeSlideSwitcher(
                  slide: -Motion.cardSlide,
                  durationIn: Motion.cardIn,
                  durationOut: Motion.cardOut,
                  child: _panelOpen && _today.isNotEmpty
                      ? Material(
                          type: MaterialType.transparency,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: TodayCard(
                              entries: _today,
                              onDone: _markDone,
                              onClose: _togglePanel,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page of the pager: loads the data and the font, then shows the page. While the font is
/// loading only the page number is drawn (spec FR-008a).
class _PageItem extends StatefulWidget {
  const _PageItem({
    required this.page,
    required this.meta,
    required this.mushaf,
    required this.fonts,
    required this.highlightedWordIds,
    required this.reveal,
    required this.ayahMarks,
    required this.onAyahLongPress,
    required this.onPageNumberTap,
    required this.onLockChanged,
    required this.onEdgeTurn,
    required this.onGone,
  });

  final int page;
  final MushafMeta meta;
  final MushafRepository mushaf;
  final PageFontLoader fonts;

  /// Words to highlight on this page (the ayah whose menu is open).
  final Set<int> highlightedWordIds;

  /// The found ayah's words to bring into view on this page (feature 011); null for every other page and when none was found.
  final PageReveal? reveal;

  /// The ayat that have an ayah bookmark of the current scope (feature 013): this page tints its own words of them.
  final ValueListenable<Set<AyahRef>> ayahMarks;

  /// A long press on a word of this page's [PageData].
  final void Function(PageData data, MushafWord word) onAyahLongPress;

  /// A tap on this page's number.
  final VoidCallback onPageNumberTap;

  /// Forwarded from the page's [PageViewport].
  final void Function(int page, bool locked) onLockChanged;
  final void Function(PageTurn turn) onEdgeTurn;

  /// The page left the pager.
  final void Function(int page) onGone;

  @override
  State<_PageItem> createState() => _PageItemState();
}

class _PageItemState extends State<_PageItem> {
  /// Built with `--dart-define=PAGE_TURN_TRACE=true`, each page logs how long it took from being
  /// created (when it starts sliding in) until its text was painted: `PAGETURN page=<n> ms=<t>`
  /// (spec SC-007, quickstart section 5). Off, and free, in normal builds.
  static const bool _trace = bool.fromEnvironment('PAGE_TURN_TRACE');

  final Stopwatch _sinceCreated = Stopwatch()..start();
  late final Future<(PageData, String)> _future = _load();

  @override
  void dispose() {
    widget.onGone(widget.page);
    super.dispose();
  }

  (PageData, String)? get _ready {
    final data = widget.mushaf.peek(widget.page);
    if (data == null || !widget.fonts.isLoaded(widget.page)) return null;
    return (data, PageFontLoader.familyOf(widget.page));
  }

  Future<(PageData, String)> _load() async {
    final data = await widget.mushaf.loadPage(widget.page);
    final family = await widget.fonts.ensure(widget.page);
    if (_trace) {
      // The frame after this future completes is the one that draws the text.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint(
          'PAGETURN page=${widget.page} ms=${_sinceCreated.elapsedMilliseconds}',
        );
      });
      WidgetsBinding.instance.scheduleFrame();
    }
    return (data, family);
  }

  // The card of the page, made again only when something it shows changed (feature 010 T010): the same instance in the
  // next build stops the framework at the card, so a rebuild of the screen no longer rebuilds the ~640 elements of the
  // page. Its two callbacks read the current widget, so keeping the instance never keeps an old callback.
  MushafPageCard? _card;
  PageData? _cardData;
  String? _cardFamily;
  PageLook? _cardLook;
  MushafMeta? _cardMeta;
  Set<int> _cardHighlight = const {};
  Set<int> _cardTint = const {};

  MushafPageCard _cardFor(
    PageData data,
    String family,
    PageLook look,
    Set<int> tint,
  ) {
    final cached = _card;
    final highlight = widget.highlightedWordIds;
    if (cached != null &&
        identical(_cardData, data) &&
        _cardFamily == family &&
        _cardLook == look &&
        identical(_cardMeta, widget.meta) &&
        setEquals(_cardHighlight, highlight) &&
        setEquals(_cardTint, tint)) {
      return cached;
    }
    _cardData = data;
    _cardFamily = family;
    _cardLook = look;
    _cardMeta = widget.meta;
    _cardHighlight = highlight;
    _cardTint = tint;
    return _card = MushafPageCard(
      data: data,
      meta: widget.meta,
      fontFamily: family,
      look: look,
      highlightedWordIds: highlight,
      tintedWordIds: tint,
      onWordLongPress: (word) => widget.onAyahLongPress(data, word),
      onPageNumberTap: () => widget.onPageNumberTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The owner's chosen look of the page (Emerald & Gold when the app has no look setting); it changes live.
    final look = context.watch<AppLookSettings?>()?.pageLook ?? PageLook.screen;
    // The Settings switch of the tint (feature 013, FR-024); an app with no such setting tints.
    final tintOn = context.watch<AyahTintSettings?>()?.enabled ?? true;
    final page = FutureBuilder<(PageData, String)>(
      future: _future,
      // A page whose text and font are already there (a neighbour prepared at rest, a page seen a moment ago) has its
      // text in its first frame instead of one frame with the page number alone (feature 010 T012).
      initialData: _ready,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        if (loaded == null) {
          return MushafPageCard.loading(page: widget.page, look: look);
        }
        // Only this builder runs when the bookmarked ayat change, and the card is made again only if the words of this page
        // that are tinted changed (setEquals in _cardFor): a bookmark of another page builds no MushafPage (FR-026).
        return ValueListenableBuilder<Set<AyahRef>>(
          valueListenable: widget.ayahMarks,
          builder: (context, marks, _) => _cardFor(
            loaded.$1,
            loaded.$2,
            look,
            tintOn ? ayahTintIds(loaded.$1, marks) : const {},
          ),
        );
      },
    );
    // The size setting scales the page card as a whole; PageViewport gives it its box, its scrolling and its zoom.
    final factor = context.watch<TextSizeSettings?>()?.factor ?? 1.0;
    return PageViewport(
      page: widget.page,
      factor: factor,
      onLockChanged: widget.onLockChanged,
      onEdgeTurn: widget.onEdgeTurn,
      reveal: widget.reveal,
      child: page,
    );
  }
}

String _juzHizbQuarter(MushafMeta meta, int page) {
  final quarter = meta.hizbQuarterOf(page); // 1..240
  final hizb = (quarter + 3) ~/ 4; // 1..60
  final inHizb = (quarter - 1) % 4 + 1; // 1..4
  return 'جزء ${meta.juzOf(page)} · حزب $hizb · ربع $inHizb';
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.meta,
    required this.page,
    required this.wirdName,
    required this.showBrowseBanner,
    required this.today,
    required this.todayOpen,
    required this.onToggleToday,
    required this.onOpenIndex,
    required this.onOpenWirds,
    required this.onMakePosition,
    required this.pageBookmarked,
    required this.onToggleBookmark,
  }) : super(key: const ValueKey('top-bar'));

  final MushafMeta meta;
  final int page;
  final String? wirdName;
  final bool showBrowseBanner;
  final List<TodayEntry> today;
  final bool todayOpen;
  final VoidCallback onToggleToday;
  final VoidCallback onOpenIndex;
  final VoidCallback onOpenWirds;
  final VoidCallback onMakePosition;

  /// The bookmark icon (feature 006): true while the page has a bookmark of the current scope, and its tap.
  final ValueListenable<bool> pageBookmarked;
  final VoidCallback onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final surahs = meta
        .surahsOn(page)
        .map((n) => meta.surah(n).name)
        .join(' · ');
    final bars = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            key: const ValueKey('open-index'),
            onTap: onOpenIndex,
            // First child is on the right (RTL): the surah name on the right, juz · hizb · quarter on
            // the left, both on one text baseline.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      surahs,
                      softWrap: false,
                      style: headingStyle(20, look.heading),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _juzHizbQuarter(meta, page),
                      key: const ValueKey('juz-hizb'),
                      style: TextStyle(fontSize: 13, color: look.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 48 px at the end (the left edge) are kept for the bookmark icon, which sits under the juz text.
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 48),
            child: SizedBox(
              height: 36,
              // Pill, today chip and «اجعلها موضعي» share the width; the last two shrink their text
              // instead of overflowing on a narrow phone.
              child: Row(
                mainAxisAlignment: showBrowseBanner
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      // Tapping the wird's name opens the wirds list, like «أوراد» in the bottom bar.
                      child: InkWell(
                        key: const ValueKey('wird-pill'),
                        customBorder: const StadiumBorder(),
                        onTap: onOpenWirds,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: look.controlBorder),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  // Night's dot is 6 px, Emerald's stays 7.
                                  width: look.dotMarkers ? 6 : 7,
                                  height: look.dotMarkers ? 6 : 7,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: look.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  // Another wird: the new name is there at once and fades in over 160 ms; there is one
                                  // name at any time and the pill keeps its size (feature 010 T034).
                                  child: FadeInOnChange(
                                    value: wirdName,
                                    child: Text(
                                      wirdName ?? 'تصفح',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: look.text,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: TodaySummaryChip(
                        entries: today,
                        open: todayOpen,
                        onTap: onToggleToday,
                      ),
                    ),
                  ),
                  if (showBrowseBanner)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: onMakePosition,
                          child: const Text('اجعلها موضعي'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    // The icon is a Stack child at the end edge of the bar (bottom 0, 48 x 48): its centre is the second row's centre,
    // under the juz text, and it adds nothing to the bar's height (research D1).
    return Stack(
      fit: StackFit.expand,
      children: [
        bars,
        PositionedDirectional(
          end: 10,
          bottom: 0,
          child: BookmarkButton(
            page: page,
            bookmarked: pageBookmarked,
            onPressed: onToggleBookmark,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onWirds,
    required this.onBookmarks,
    required this.onSettings,
  }) : super(key: const ValueKey('bottom-bar'));

  final VoidCallback onWirds;
  final VoidCallback onBookmarks;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final items = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const _BarItem(icon: Icons.headphones, label: 'استماع', soon: true),
        _BarItem(
          icon: Icons.bookmark_border,
          label: 'علامات',
          onTap: onBookmarks,
        ),
        _BarItem(icon: Icons.menu_book, label: 'أوراد', onTap: onWirds),
        const _BarItem(icon: Icons.quiz_outlined, label: 'اختبار', soon: true),
        IconButton(
          key: const ValueKey('open-settings'),
          icon: const Icon(Icons.menu),
          color: look.heading,
          tooltip: 'القائمة',
          onPressed: onSettings,
        ),
      ],
    );
    if (!look.floatingBar) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: look.barFill,
          border: Border(top: BorderSide(color: look.barBorder)),
        ),
        child: items,
      );
    }
    // Night Reader: a floating pill, 56 px high, 6 px above and below and 16 px from the sides, inside the same
    // 68 px slot, so the page area is the size it is in Emerald & Gold (research D5).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.barFill,
          border: Border.all(color: look.barBorder),
          borderRadius: BorderRadius.circular(28),
        ),
        child: items,
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    this.soon = false,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Disabled and labelled «قريباً» until its feature exists.
  final bool soon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    // In the 56 px pill of Night the labels get a fixed line height so the column always fits, and the item is a
    // 48 px target; Emerald & Gold's bar is exactly as it was.
    final pill = look.floatingBar;
    final style = TextStyle(
      fontSize: 11,
      color: look.heading,
      height: pill ? 1.1 : null,
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: look.heading),
        Text(label, style: style),
        if (soon)
          Text(
            'قريباً',
            style: TextStyle(
              fontSize: 9,
              color: look.heading,
              height: pill ? 1.1 : null,
            ),
          ),
      ],
    );
    return Opacity(
      opacity: soon ? 0.5 : 1,
      child: InkWell(
        onTap: soon ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: pill ? 2 : 4),
          child: pill
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(widthFactor: 1, child: column),
                )
              : column,
        ),
      ),
    );
  }
}
