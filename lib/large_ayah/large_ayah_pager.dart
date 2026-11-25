import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../ayah/ayah_ref.dart';
import '../khatm/last_page_swipe.dart';
import '../mushaf/models.dart';
import '../mushaf/page_look.dart';
import 'large_ayah_screen.dart';
import 'page_screens.dart';
import 'screen_layout.dart';
import 'screen_navigator.dart';

/// Where the pager opens: the first screen of a page, or the screen that holds an ayah. A new [token] re-anchors the
/// pager even to the same place (a second jump to the page already shown).
@immutable
class LargeTarget {
  const LargeTarget.page(int this.page, {this.token = 0}) : ayah = null;
  const LargeTarget.ayah(AyahRef this.ayah, {this.token = 0}) : page = null;

  final int? page;
  final AyahRef? ayah;
  final int token;

  @override
  bool operator ==(Object other) =>
      other is LargeTarget && other.page == page && other.ayah == ayah && other.token == token;

  @override
  int get hashCode => Object.hash(page, ayah, token);
}

/// The anchored pager of the large-ayah view (feature 015, research D5). The pager's virtual index [_base] is the anchor
/// screen; the screens around it are found one step at a time through a [ScreenNavigator]. The next screen comes in from
/// the left, as a Mushaf page does (reverse in an LTR box). The start stops at the first screen of page 1, and a swipe
/// past the last screen of page 604 calls [onPastEnd] (as [LastPageSwipe] does for the Mushaf).
class LargeAyahPager extends StatefulWidget {
  const LargeAyahPager({
    super.key,
    required this.sourceFor,
    required this.pageOfAyah,
    required this.meta,
    required this.factor,
    required this.target,
    this.layoutKey,
    this.look = PageLook.screen,
    this.highlightedWordIds = const {},
    this.ayahMarks,
    this.onScreenShown,
    this.onWordLongPress,
    this.onTap,
    this.onPastEnd,
  });

  /// The screens of every page for a geometry (the count is the caller's, named by [layoutKey]).
  final ScreenSource Function(LargeGeometry geometry) sourceFor;
  final int Function(AyahRef) pageOfAyah;
  final MushafMeta meta;

  /// The size factor (research D2).
  final double factor;
  final LargeTarget target;

  /// Changes when the screens change for another reason than the box or the size (the count): the pager then re-anchors
  /// at the first ayah of the screen shown.
  final Object? layoutKey;
  final PageLook look;
  final Set<int> highlightedWordIds;

  /// The ayat that are tinted (feature 013); null for none.
  final ValueListenable<Set<AyahRef>>? ayahMarks;
  final ValueChanged<LargeScreen>? onScreenShown;
  final void Function(int page, MushafWord word)? onWordLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onPastEnd;

  @override
  State<LargeAyahPager> createState() => _LargeAyahPagerState();
}

class _LargeAyahPagerState extends State<LargeAyahPager> {
  static const int _base = 100000;

  final _Bounds _bounds = _Bounds();
  final LastPageSwipe _lastSwipe = LastPageSwipe();
  PageController _controller = PageController(initialPage: _base);
  LargeGeometry? _geometry;
  ScreenNavigator? _nav;
  final Map<int, ScreenRef> _refs = {};
  final Map<int, LargeScreen> _screens = {};
  int _current = _base;
  int _epoch = 0;
  bool _pendingAnchor = true;

  /// True from a change of the box until the screens of the new box are ready: the old screens were laid out for the old
  /// box and are not drawn in the new one.
  bool _stale = false;

  /// The ayah the pager was last anchored at (see [_rebuildKeepingAyah]).
  AyahRef? _anchorAyah;

  @override
  void didUpdateWidget(LargeAyahPager old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _anchorTo(widget.target);
    } else if (old.layoutKey != widget.layoutKey || old.factor != widget.factor) {
      _rebuildKeepingAyah();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureGeometry(BoxConstraints c) {
    final g = LargeGeometry(width: c.maxWidth, height: c.maxHeight, factor: widget.factor);
    if (g == _geometry) return;
    final first = _geometry == null;
    _geometry = g;
    // Laid out in the next microtask: the box changed during a build.
    if (first) {
      _nav = _navigator(g);
      scheduleMicrotask(() => _anchorTo(widget.target));
    } else {
      _stale = true;
      scheduleMicrotask(_rebuildKeepingAyah);
    }
  }

  ScreenNavigator _navigator(LargeGeometry g) => ScreenNavigator(widget.sourceFor(g), pageOfAyah: widget.pageOfAyah);

  /// The first ayah of the screen shown, or null while none is shown.
  AyahRef? get _shownAyah => _screens[_current]?.ayat.first;

  Future<void> _rebuildKeepingAyah() async {
    final g = _geometry;
    if (g == null || !mounted) return;
    _geometry = LargeGeometry(width: g.width, height: g.height, factor: widget.factor);
    _nav = _navigator(_geometry!);
    _stale = true;
    // The ayah the pager was anchored at, while the reader has not moved from it (so 1 → 2 → 1 ayat comes back to the
    // same screen); else the first ayah of the screen shown.
    final ayah = _current == _base && _anchorAyah != null ? _anchorAyah : _shownAyah;
    await _anchorTo(ayah == null ? widget.target : LargeTarget.ayah(ayah), keepAnchorAyah: true);
  }

  Future<void> _anchorTo(LargeTarget target, {bool keepAnchorAyah = false}) async {
    final nav = _nav;
    if (nav == null || !mounted) return;
    final epoch = ++_epoch;
    _pendingAnchor = true;
    final ref = target.ayah != null ? await nav.screenOfAyah(target.ayah!) : await nav.firstOf(target.page!);
    final screen = await nav.screen(ref);
    if (!mounted || epoch != _epoch) return;
    if (!keepAnchorAyah) _anchorAyah = target.ayah ?? screen.ayat.first;
    final old = _controller;
    setState(() {
      _refs
        ..clear()
        ..[_base] = ref;
      _screens
        ..clear()
        ..[_base] = screen;
      _bounds
        ..min = null
        ..max = null;
      _current = _base;
      _controller = PageController(initialPage: _base);
      _pendingAnchor = false;
      _stale = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    widget.onScreenShown?.call(screen);
    unawaited(_resolveAround(_base, epoch));
  }

  /// Finds the screens two steps on each side of [index].
  Future<void> _resolveAround(int index, int epoch) async {
    final nav = _nav;
    if (nav == null) return;
    for (final dir in const [1, -1]) {
      for (var step = 1; step <= 2; step++) {
        final i = index + dir * step;
        if (_refs.containsKey(i)) continue;
        final from = _refs[i - dir];
        if (from == null) break;
        final ref = dir > 0 ? await nav.next(from) : await nav.previous(from);
        if (!mounted || epoch != _epoch) return;
        if (ref == null) {
          setState(() => dir > 0 ? _bounds.max = i - dir : _bounds.min = i - dir);
          break;
        }
        final screen = await nav.screen(ref);
        if (!mounted || epoch != _epoch) return;
        setState(() {
          _refs[i] = ref;
          _screens[i] = screen;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    _current = index;
    final screen = _screens[index];
    if (screen != null) widget.onScreenShown?.call(screen);
    unawaited(_resolveAround(index, _epoch));
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.horizontal) return false;
    if (n is ScrollStartNotification) {
      _lastSwipe.start();
    } else if (n is OverscrollNotification) {
      if (n.overscroll > 0 && _bounds.max == _current) _lastSwipe.overscroll(n.overscroll);
    } else if (n is ScrollEndNotification) {
      final velocity = n.dragDetails?.velocity.pixelsPerSecond.dx ?? 0;
      if (_lastSwipe.end(velocity: velocity) && _bounds.max == _current) widget.onPastEnd?.call();
    }
    return false;
  }

  Set<int> _tinted(LargeScreen screen, Set<AyahRef> marks) => marks.isEmpty
      ? const {}
      : {
          for (final w in screen.words)
            if (marks.contains(AyahRef(w.surah, w.ayah))) w.id,
        };

  Widget _item(int index) {
    final screen = _screens[index];
    final g = _geometry;
    if (screen == null || g == null || _stale) return ColoredBox(color: widget.look.paper);
    Widget build(Set<AyahRef> marks) => LargeAyahScreen(
      screen: screen,
      meta: widget.meta,
      geometry: g,
      look: widget.look,
      highlightedWordIds: widget.highlightedWordIds,
      tintedWordIds: _tinted(screen, marks),
      onWordLongPress: widget.onWordLongPress == null ? null : (w) => widget.onWordLongPress!(screen.page, w),
    );
    final marks = widget.ayahMarks;
    return marks == null
        ? build(const {})
        : ValueListenableBuilder<Set<AyahRef>>(valueListenable: marks, builder: (_, m, _) => build(m));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _ensureGeometry(constraints);
      if (_pendingAnchor && _screens.isEmpty) return ColoredBox(color: widget.look.paper);
      return Directionality(
        // LTR + reverse: the next screen comes in from the left, like the paper Mushaf.
        textDirection: TextDirection.ltr,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: PageView.builder(
            key: ValueKey(_epoch),
            reverse: true,
            controller: _controller,
            physics: _BoundedPagePhysics(_bounds),
            allowImplicitScrolling: true,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) =>
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: _item(index)),
          ),
        ),
      );
    },
  );
}

/// The known first and last pager index; null while not reached.
class _Bounds {
  int? min;
  int? max;
}

/// Page physics that stop at the known ends ([_Bounds]), as at the ends of a pager with a fixed item count.
class _BoundedPagePhysics extends PageScrollPhysics {
  const _BoundedPagePhysics(this.bounds, {super.parent});

  final _Bounds bounds;

  @override
  _BoundedPagePhysics applyTo(ScrollPhysics? ancestor) => _BoundedPagePhysics(bounds, parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final dim = position.viewportDimension;
    final min = bounds.min == null ? double.negativeInfinity : bounds.min! * dim;
    final max = bounds.max == null ? double.infinity : bounds.max! * dim;
    if (value < position.pixels && position.pixels <= min) return value - position.pixels;
    if (max <= position.pixels && position.pixels < value) return value - position.pixels;
    if (value < min && min < position.pixels) return value - min;
    if (position.pixels < max && max < value) return value - max;
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final dim = position.viewportDimension;
    final min = bounds.min == null ? null : bounds.min! * dim;
    final max = bounds.max == null ? null : bounds.max! * dim;
    if (min != null && position.pixels < min) {
      return ScrollSpringSimulation(spring, position.pixels, min, velocity, tolerance: toleranceFor(position));
    }
    if (max != null && position.pixels > max) {
      return ScrollSpringSimulation(spring, position.pixels, max, velocity, tolerance: toleranceFor(position));
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
