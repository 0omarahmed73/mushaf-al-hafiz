import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'tip_steps.dart';

/// The size every drawing is laid out in; the panel scales it down to fit a narrower or shorter box and never up
/// (research D10).
const Size kTipPictureDesignSize = Size(240, 112);

/// How long the long-press ring takes to grow and fade.
const Duration kTipPulseDuration = Duration(milliseconds: 1400);

/// The drawing of one step (feature 008, research D10): rounded rectangles, bars and the app's own icons on a panel in
/// the colours of the chosen look. No text and no Quran word: only shapes. Excluded from the semantics.
///
/// Only the long-press drawing moves: a ring grows and fades over the ayah's line. It runs only while [active] (the
/// step is the one shown), so a step that is not on screen never schedules a frame.
class TipPictureView extends StatefulWidget {
  const TipPictureView({
    super.key,
    required this.picture,
    required this.active,
  });

  final TipPicture picture;

  /// True only for the step on screen.
  final bool active;

  @override
  State<TipPictureView> createState() => _TipPictureViewState();
}

class _TipPictureViewState extends State<TipPictureView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: kTipPulseDuration,
  );

  /// The ring moves only on its own step and never when the phone asks for reduced motion (spec FR-013).
  bool get _pulses =>
      widget.active &&
      widget.picture == TipPicture.longPress &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(TipPictureView old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  void _syncPulse() {
    if (_pulses) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else if (_pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.background,
          border: Border.all(color: look.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          // Every position below is explicit (left, right), so the drawing reads the same whatever the app's direction.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: kTipPictureDesignSize.width,
              height: kTipPictureDesignSize.height,
              child: switch (widget.picture) {
                TipPicture.longPress => _LongPress(
                  pulse: _pulse,
                  moving: _pulses,
                ),
                TipPicture.turnPages => const _TurnPages(),
                TipPicture.barsAndZoom => const _BarsAndZoom(),
                TipPicture.wird => const _Wird(),
                TipPicture.bookmarks => const _Bookmarks(),
                TipPicture.sizeAndLook => const _SizeAndLook(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------------------------- pieces

/// A little Mushaf page: a card with lines of text drawn as bars. [highlight] is the line (0-based) drawn in the
/// accent colour, like the highlighted ayah.
class _Page extends StatelessWidget {
  const _Page({
    this.lines = 6,
    this.highlight,
    this.top,
    this.bottom,
    this.child,
  });

  final int lines;
  final int? highlight;

  /// Bars at the top and the bottom of the page (the reader's two bars).
  final Widget? top;
  final Widget? bottom;

  /// Drawn over the page (an icon).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: look.cardFill,
        border: Border.all(color: look.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                9,
                top == null ? 10 : 20,
                9,
                bottom == null ? 8 : 18,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < lines; i++)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: i == highlight ? look.accentAlt : look.cardMuted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const SizedBox(height: 5, width: double.infinity),
                    ),
                ],
              ),
            ),
            if (top != null)
              Positioned(left: 0, right: 0, top: 0, height: 13, child: top!),
            if (bottom != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 13,
                child: bottom!,
              ),
            ?child,
          ],
        ),
      ),
    );
  }
}

/// One of the reader's two bars, drawn as a strip with a dot.
class _Strip extends StatelessWidget {
  const _Strip();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return ColoredBox(
      color: look.barFill,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(color: look.accent, shape: BoxShape.circle),
          child: const SizedBox(width: 5, height: 5),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: look.controlBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: child,
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: SizedBox(width: width, height: 5),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: look.cardFill,
        border: Border.all(color: look.cardBorderStrong),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 24, color: look.cardInk),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------ the six drawings

/// Step 1: a long press on a line of the page (the ring) opens a menu card with three rows.
class _LongPress extends StatelessWidget {
  const _LongPress({required this.pulse, required this.moving});

  final Animation<double> pulse;
  final bool moving;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Stack(
      children: [
        const Positioned(
          right: 16,
          top: 8,
          bottom: 8,
          width: 112,
          child: _Page(highlight: 2),
        ),
        // The press: a solid dot and a ring around it that grows and fades; still (half grown) when it does not move.
        Positioned(
          right: 74,
          top: 38,
          width: 36,
          height: 36,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final t = moving ? pulse.value : 0.5;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: 0.55 + 0.45 * t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: look.accentAlt.withValues(alpha: 1 - 0.7 * t),
                          width: 2.5,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: look.accentAlt,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 9, height: 9),
                  ),
                ],
              );
            },
          ),
        ),
        // The menu card: tafsir, translation, share.
        Positioned(
          left: 16,
          top: 14,
          width: 84,
          height: 84,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: look.cardFill,
              border: Border.all(color: look.cardBorderStrong),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final icon in const [
                  Icons.menu_book,
                  Icons.translate,
                  Icons.share,
                ])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: look.cardInk),
                      const SizedBox(width: 8),
                      _Bar(width: 28, color: look.cardMuted),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 2: a finger and an arrow pointing right (the swipe from left to right), the next page coming from the left.
class _TurnPages extends StatelessWidget {
  const _TurnPages();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Stack(
      children: [
        const Positioned(
          left: 20,
          top: 16,
          width: 64,
          height: 80,
          child: _Page(lines: 5),
        ),
        Positioned(
          left: 92,
          top: 0,
          bottom: 0,
          width: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 30, color: look.accent),
              const SizedBox(height: 2),
              Icon(Icons.east, size: 30, color: look.accent),
            ],
          ),
        ),
        // The surah-name row at the top of the current page, which opens the index.
        Positioned(
          right: 20,
          top: 8,
          width: 84,
          height: 96,
          child: _Page(
            top: Center(child: _Bar(width: 40, color: look.accentAlt)),
          ),
        ),
      ],
    );
  }
}

/// Step 3: a page with the reader's two bars, a tap, and two fingers apart.
class _BarsAndZoom extends StatelessWidget {
  const _BarsAndZoom();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Stack(
      children: [
        Positioned(
          left: 22,
          top: 6,
          width: 92,
          height: 100,
          child: _Page(
            top: const _Strip(),
            bottom: const _Strip(),
            child: Center(
              child: Icon(Icons.touch_app, size: 30, color: look.cardInk),
            ),
          ),
        ),
        Positioned(
          right: 22,
          top: 0,
          bottom: 0,
          width: 70,
          child: Center(child: Icon(Icons.pinch, size: 52, color: look.accent)),
        ),
      ],
    );
  }
}

/// Step 4: the wird's pill and «ملخص اليوم» at the top, and today's portion with its tick.
class _Wird extends StatelessWidget {
  const _Wird();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Stack(
      children: [
        Positioned(
          left: 20,
          top: 12,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Pill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: look.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 7, height: 7),
                    ),
                    const SizedBox(width: 8),
                    _Bar(width: 44, color: look.textSecondary),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Pill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Bar(width: 36, color: look.textSecondary),
                    Icon(Icons.expand_more, size: 16, color: look.accent),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 54,
          height: 46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: look.cardFill,
              border: Border.all(color: look.cardBorderStrong),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: look.accentAlt,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 10, height: 10),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bar(width: 70, color: look.cardInk),
                      const SizedBox(height: 7),
                      _Bar(width: 46, color: look.cardMuted),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.check_circle_outline,
                    size: 26,
                    color: look.cardInk,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 5: an outlined bookmark becomes a filled one.
class _Bookmarks extends StatelessWidget {
  const _Bookmarks();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Stack(
      children: [
        Positioned(
          left: 28,
          top: 10,
          width: 72,
          height: 92,
          child: _Page(
            lines: 5,
            child: Align(
              alignment: Alignment.topLeft,
              child: Icon(Icons.bookmark_border, size: 26, color: look.cardInk),
            ),
          ),
        ),
        Positioned(
          left: 104,
          top: 0,
          bottom: 0,
          width: 32,
          child: Center(child: Icon(Icons.east, size: 30, color: look.accent)),
        ),
        Positioned(
          right: 28,
          top: 10,
          width: 72,
          height: 92,
          child: _Page(
            lines: 5,
            child: Align(
              alignment: Alignment.topLeft,
              child: Icon(Icons.bookmark, size: 26, color: look.cardInk),
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 6: the menu button leads to a text-size tile and a look tile.
class _SizeAndLook extends StatelessWidget {
  const _SizeAndLook();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: look.controlBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.menu, size: 28, color: look.accent),
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.east, size: 28, color: look.accent),
        const SizedBox(width: 12),
        const _Tile(icon: Icons.format_size),
        const SizedBox(width: 10),
        const _Tile(icon: Icons.dark_mode),
      ],
    );
  }
}
