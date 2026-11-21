import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'page_scale.dart';

/// Asks a [PageViewport] to bring words into view, once per [token] (feature 011; research D4). A new token acts again, the
/// same token never does, so a parent that rebuilds with the same value moves nothing. [wordIds] are the ids of the words
/// (`ValueKey('w<id>')` on the page) that must be seen: the part of a found ayah that is on this page.
class PageReveal {
  const PageReveal(this.wordIds, this.token);

  final Set<int> wordIds;
  final int token;
}

/// Gives one Mushaf page its size in the reader (spec FR-007, FR-008, FR-010; research D2, D3).
///
/// [child] is the page card; it is laid out in a box of today's size times [factor] ([PageBox]) and so keeps its
/// layout. Smaller than the screen it is centred; taller it scrolls up and down (the landscape page of feature
/// 001); wider than the screen it moves up, down and sideways inside an [InteractiveViewer], starts at its top
/// and right side, and a one-finger swipe that starts at a side edge and moves outward asks the reader for the
/// next or previous page through [onEdgeTurn]. Pinch zoom (1x to 3x of the sized page) works in every case.
///
/// The widget owns its own transformation, so a page that comes in during a page turn shows its own start
/// position and a page that scrolled out of the pager is forgotten and starts fresh when shown again.
class PageViewport extends StatefulWidget {
  const PageViewport({
    super.key,
    required this.page,
    required this.factor,
    required this.child,
    required this.onLockChanged,
    required this.onEdgeTurn,
    this.reveal,
  });

  /// The Mushaf page number, handed back to [onLockChanged].
  final int page;

  /// The size setting as a factor: 0.8 .. 1.5.
  final double factor;
  final Widget child;

  /// Called when the pager must be locked for this page (it is wider than the screen, or zoomed in) or may turn
  /// pages by swiping again. Also called once with the first state.
  final void Function(int page, bool locked) onLockChanged;

  /// A swipe from a side edge asks for the next or the previous page.
  final void Function(PageTurn turn) onEdgeTurn;

  /// Brings the words of [PageReveal.wordIds] into view once per token, after the page shows them (they may appear a few
  /// frames after the page itself, which is built after its data and font are loaded). Optional: null changes nothing, and
  /// nothing is scheduled. A page that is zoomed in is put back to scale 1 first. It never animates. In the three fits:
  /// [PageFit.fits] nothing moves (the whole page is on the screen); [PageFit.scrollsVertically] scrolls so that the first
  /// word is about 30% from the top; [PageFit.pansBothWays] moves the page just enough to put the words inside the viewport
  /// with a 24 dp margin, and puts the first word at the right edge when they are wider than the screen. The first line of the
  /// words is always in view, all of them when the screen can hold them.
  final PageReveal? reveal;

  @override
  State<PageViewport> createState() => _PageViewportState();
}

class _PageViewportState extends State<PageViewport> {
  static const double _zoomedAbove = 1.01;

  // The reveal (research D4): how many frames it waits for its words, the margin it keeps, and where the first word goes when
  // the page scrolls.
  static const int _revealFrames = 60;
  static const double _revealMargin = 24;
  static const double _revealAlignment = 0.3;

  final TransformationController _ctl = TransformationController();
  PageBox? _box;
  bool _zoomed = false;
  bool? _reportedLock;

  // The gesture being tracked for the edge turn.
  double _startX = 0;
  double _dx = 0;
  double _dy = 0;
  bool _singleFinger = true;
  bool _startedZoomed = false;

  // The reveal being waited for: its words, the frames spent, and whether a frame callback is already asked for.
  int? _handledToken;
  Set<int>? _pendingWords;
  int _framesWaited = 0;
  bool _stepAsked = false;

  @override
  void initState() {
    super.initState();
    final reveal = widget.reveal;
    if (reveal != null) _startReveal(reveal);
  }

  @override
  void didUpdateWidget(PageViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reveal = widget.reveal;
    if (reveal == null) {
      _pendingWords = null;
    } else if (reveal.token != _handledToken) {
      _startReveal(reveal);
    }
  }

  @override
  void dispose() {
    _pendingWords = null;
    _ctl.dispose();
    super.dispose();
  }

  void _startReveal(PageReveal reveal) {
    _handledToken = reveal.token;
    _pendingWords = reveal.wordIds;
    _framesWaited = 0;
    _askStep();
  }

  /// A frame is asked for only while a reveal is pending: it ends when the words were revealed or after [_revealFrames].
  void _askStep() {
    if (_stepAsked) return;
    _stepAsked = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _stepAsked = false;
      _revealStep();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _stepAgain() {
    if (++_framesWaited >= _revealFrames) {
      _pendingWords = null;
      return;
    }
    _askStep();
  }

  /// The elements of the words [ids] under this widget (`ValueKey('w<id>')`), with their ids.
  List<(int, Element)> _findWords(Set<int> ids) {
    final found = <(int, Element)>[];
    void visit(Element element) {
      final key = element.widget.key;
      if (key is ValueKey<String> &&
          key.value.length > 1 &&
          key.value.codeUnitAt(0) == 0x77) {
        final id = int.tryParse(key.value.substring(1));
        if (id != null && ids.contains(id)) {
          found.add((id, element));
          return;
        }
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  void _revealStep() {
    final ids = _pendingWords;
    if (ids == null || !mounted) return;
    final box = _box;
    final viewport = context.findRenderObject();
    final found = _findWords(ids);
    if (found.isEmpty ||
        box == null ||
        viewport is! RenderBox ||
        !viewport.hasSize) {
      _stepAgain();
      return;
    }
    // A page that is zoomed in is put back to scale 1 first, as an arrival is; its words are measured once that is drawn.
    if (_ctl.value.getMaxScaleOnAxis() > _zoomedAbove) {
      _ctl.value = Matrix4.translationValues(
        box.startOffset.dx,
        box.startOffset.dy,
        0,
      );
      if (_zoomed) setState(() => _zoomed = false);
      _stepAgain();
      return;
    }
    Rect? union;
    Rect? firstRect;
    Element? firstElement;
    var firstId = 0;
    for (final (id, element) in found) {
      final renderBox = element.renderObject;
      if (renderBox is! RenderBox ||
          !renderBox.attached ||
          !renderBox.hasSize) {
        continue;
      }
      final rect = MatrixUtils.transformRect(
        renderBox.getTransformTo(viewport),
        Offset.zero & renderBox.size,
      );
      union = union == null ? rect : union.expandToInclude(rect);
      if (firstRect == null || id < firstId) {
        firstId = id;
        firstRect = rect;
        firstElement = element;
      }
    }
    if (union == null || firstRect == null || firstElement == null) {
      _stepAgain();
      return;
    }
    _pendingWords = null;
    switch (box.fit) {
      case PageFit.fits:
        break; // the whole page is on the screen
      case PageFit.scrollsVertically:
        _revealByScrolling(viewport.size, union, firstElement);
      case PageFit.pansBothWays:
        _revealByPanning(box, viewport.size, union, firstRect);
    }
  }

  /// Where the top of the words should be in a viewport of [viewport] when the page scrolls: the first word about 30% from the
  /// top, lower down only as far as all the words still keep a margin, and the first line at the margin when they are taller
  /// than the screen.
  double _scrollTop(double extent, double viewport) {
    if (extent > viewport) return _revealMargin;
    if (extent > viewport - 2 * _revealMargin) return (viewport - extent) / 2;
    return math.min(
      _revealAlignment * viewport,
      viewport - _revealMargin - extent,
    );
  }

  void _revealByScrolling(Size viewport, Rect union, Element first) {
    final position = Scrollable.maybeOf(first)?.position;
    if (position == null || !position.hasPixels) return;
    final target =
        (position.pixels +
                union.top -
                _scrollTop(union.height, viewport.height))
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target != position.pixels) position.jumpTo(target);
  }

  /// How far to move the words along one axis of a viewport of [size]: not at all when they are inside with the margin, as
  /// little as possible when not, and when they are longer than the viewport the start the caller names ([whenLonger], the
  /// shift that puts the first word where reading starts).
  double _shift(double start, double end, double size, double whenLonger) {
    final extent = end - start;
    if (extent > size) return whenLonger;
    if (extent > size - 2 * _revealMargin) {
      if (start < 0) return -start;
      return end > size ? size - end : 0;
    }
    if (start < _revealMargin) return _revealMargin - start;
    return end > size - _revealMargin ? size - _revealMargin - end : 0;
  }

  void _revealByPanning(PageBox box, Size viewport, Rect union, Rect first) {
    final dx = _shift(
      union.left,
      union.right,
      viewport.width,
      // Reading starts at the right: the first word goes to the right edge.
      viewport.width - _revealMargin - first.right,
    );
    final dy = _shift(
      union.top,
      union.bottom,
      viewport.height,
      _revealMargin - union.top,
    );
    if (dx == 0 && dy == 0) return;
    final now = _ctl.value.getTranslation();
    final x = (now.x + dx).clamp(viewport.width - box.content.width, 0.0);
    final y = (now.y + dy).clamp(viewport.height - box.content.height, 0.0);
    _ctl.value = Matrix4.translationValues(x, y, 0);
  }

  /// Puts a new page, size or screen at its start position: top, right side, not zoomed.
  void _arrive(PageBox box) {
    final old = _box;
    _box = box;
    final start = Matrix4.translationValues(
      box.startOffset.dx,
      box.startOffset.dy,
      0,
    );
    if (old == null) {
      // Nothing listens to the controller yet, so it may be set while building.
      _ctl.value = start;
    } else if (old.viewport != box.viewport || old.factor != box.factor) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ctl.value = start;
        if (_zoomed) setState(() => _zoomed = false);
      });
    }
  }

  void _reportLock(bool locked) {
    if (_reportedLock == locked) return;
    _reportedLock = locked;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLockChanged(widget.page, locked);
    });
  }

  void _syncZoom() {
    final zoomed = _ctl.value.getMaxScaleOnAxis() > _zoomedAbove;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _onStart(ScaleStartDetails details) {
    _startX = _ctl.value.getTranslation().x;
    _dx = 0;
    _dy = 0;
    _singleFinger = details.pointerCount == 1;
    _startedZoomed = _zoomed;
  }

  void _onUpdate(ScaleUpdateDetails details) {
    _dx += details.focalPointDelta.dx;
    _dy += details.focalPointDelta.dy;
    if (details.pointerCount > 1) _singleFinger = false;
    _syncZoom();
  }

  void _onEnd(ScaleEndDetails details) {
    _syncZoom();
    final box = _box;
    if (box == null ||
        box.fit != PageFit.pansBothWays ||
        !_singleFinger ||
        _startedZoomed ||
        _zoomed) {
      return;
    }
    final turn = edgeTurn(
      startX: _startX,
      minX: box.viewport.width - box.content.width,
      maxX: 0,
      dx: _dx,
      dy: _dy,
      vx: details.velocity.pixelsPerSecond.dx,
    );
    if (turn != PageTurn.none) widget.onEdgeTurn(turn);
  }

  Widget _viewer({
    Key? key,
    required Widget child,
    bool constrained = true,
    bool pan = false,
  }) {
    return InteractiveViewer(
      key: key,
      transformationController: _ctl,
      constrained: constrained,
      minScale: 1,
      maxScale: 3,
      boundaryMargin: EdgeInsets.zero,
      panEnabled: pan || _zoomed,
      onInteractionStart: _onStart,
      onInteractionUpdate: _onUpdate,
      onInteractionEnd: _onEnd,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = PageBox(constraints.biggest, widget.factor);
        _arrive(box);
        final page = SizedBox(
          width: box.scaled.width,
          height: box.scaled.height,
          child: widget.child,
        );
        _reportLock(box.fit == PageFit.pansBothWays || _zoomed);
        return switch (box.fit) {
          PageFit.fits => _viewer(child: Center(child: page)),
          PageFit.scrollsVertically => _viewer(
            child: SingleChildScrollView(
              key: const ValueKey('landscape-scroll'),
              child: Center(child: page),
            ),
          ),
          PageFit.pansBothWays => _viewer(
            key: const ValueKey('page-pan'),
            constrained: false,
            pan: true,
            child: SizedBox(
              width: box.content.width,
              height: box.content.height,
              child: Center(child: page),
            ),
          ),
        };
      },
    );
  }
}
