import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'app_icon_painter.dart';
import 'splash_painters.dart';
import 'splash_palette.dart';
import 'splash_plan.dart';
import 'splash_strings.dart';
import 'splash_timeline.dart';

/// The animated splash (spec FR-007 to FR-014): the night background, the icon tile that eases in, the name and the line that
/// fade up, and the thin line that fills. It owns the clock, the exit fade and the tap, and knows nothing about the app behind
/// it: [SplashGate] puts it over the app.
///
/// It needs a `Directionality` above it (the gate provides one) and uses no theme, no localisation and no provider, so the app
/// look cannot reach it. Everything is drawn with painters and explicit text styles.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.ready, this.onGone});

  /// Whether the app has finished its first loading.
  final bool ready;

  /// Called once, when the splash has faded out and can be removed.
  final VoidCallback? onGone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Ticker _ticker = Ticker(_onTick);
  Duration _elapsed = Duration.zero;

  /// When the splash started to leave (on the same clock as [_elapsed]); null while it plays.
  Duration? _leaveAt;
  bool _gone = false;
  bool _skipped = false;
  bool _endPainted = false;

  /// The phone's «remove animations» setting: the splash is drawn finished and still, and leaves without a fade.
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A change while the splash plays is followed at once; the clock keeps running, it is not restarted.
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _decideToLeave();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;
    _decideToLeave();
    final leaveAt = _leaveAt;
    if (leaveAt != null && elapsed - leaveAt >= _fadeLength && !_gone) {
      _gone = true;
      _ticker.stop();
      widget.onGone?.call();
      return;
    }
    // Once the timeline has ended (and its last frame is drawn) and the splash is waiting for the app, nothing changes between
    // frames.
    if (_reducedMotion) return; // nothing moves
    if (elapsed < SplashPlan.fullDuration || leaveAt != null || !_endPainted) {
      _endPainted = elapsed >= SplashPlan.fullDuration;
      setState(() {});
    }
  }

  /// Starts the exit when [SplashPlan.mayLeave] first says so. Called on every frame and whenever the app becomes ready or the
  /// owner taps, so the exit begins on the frame the condition holds.
  void _decideToLeave() {
    if (_leaveAt != null) return;
    if (SplashPlan.mayLeave(
      elapsed: _elapsed,
      ready: widget.ready,
      skipped: _skipped,
      reducedMotion: _reducedMotion,
    )) {
      _leaveAt = _elapsed;
    }
  }

  void _skip() {
    _skipped = true;
    setState(_decideToLeave);
  }

  @override
  void didUpdateWidget(SplashScreen old) {
    super.didUpdateWidget(old);
    if (old.ready != widget.ready) _decideToLeave();
  }

  Duration get _fadeLength => _reducedMotion ? Duration.zero : SplashPlan.fade;

  /// 0 while the splash is fully shown, 1 when it has faded out.
  double get _fade {
    final leaveAt = _leaveAt;
    if (leaveAt == null) return 0;
    if (_reducedMotion) return 0; // it is cut away, not faded
    final t =
        (_elapsed - leaveAt).inMicroseconds / SplashPlan.fade.inMicroseconds;
    return t.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final frame = _reducedMotion
        ? SplashTimeline.finalFrame
        : SplashTimeline.at(_elapsed);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: Semantics(
        container: true,
        label: '$kSplashName. $kSplashTagline',
        excludeSemantics: true,
        child: Opacity(
          opacity: 1 - _fade,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: SplashBackgroundPainter(
                  backdrop: frame.backdrop,
                  stars: frame.stars,
                ),
              ),
              // The design lifts the middle block 30 px above the centre.
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Center(child: _Middle(frame: frame)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 64,
                child: Center(
                  child: SizedBox(
                    key: const ValueKey('splash-progress'),
                    width: 120,
                    height: 3,
                    child: CustomPaint(
                      painter: ProgressLinePainter(progress: frame.progress),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The icon tile, the name and the line, in a column. The column shrinks to fit rather than overflow (a very large system font
/// on a small phone), and the line wraps at the screen's width.
class _Middle extends StatelessWidget {
  const _Middle({required this.frame});

  final SplashFrame frame;

  static const TextStyle _name = TextStyle(
    fontFamily: 'ReemKufi',
    fontVariations: [FontVariation('wght', 700)],
    fontSize: 44,
    color: SplashColors.name,
    decoration: TextDecoration.none,
  );

  static const TextStyle _line = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 15,
    height: 1.7,
    color: SplashColors.tagline,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - 48).clamp(0.0, double.infinity)
            : double.infinity;
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Tile(frame: frame),
                const SizedBox(height: 22),
                Opacity(
                  opacity: frame.nameOpacity,
                  child: Transform.translate(
                    offset: Offset(0, frame.nameRise),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(kSplashName, style: _name),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: frame.lineOpacity,
                  child: Transform.translate(
                    offset: Offset(0, frame.lineRise),
                    child: const Text(
                      kSplashTagline,
                      style: _line,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The 132 px rounded tile with the icon in it and its teal glow.
class _Tile extends StatelessWidget {
  const _Tile({required this.frame});

  final SplashFrame frame;

  static final BorderRadius _radius = BorderRadius.circular(34);

  /// The glow and the drop shadow: static, so they sit in a layer of their own that is drawn once.
  static final BoxDecoration _shadow = BoxDecoration(
    borderRadius: _radius,
    boxShadow: [
      BoxShadow(
        color: SplashColors.star.withValues(alpha: 0.28),
        blurRadius: 60,
      ),
      const BoxShadow(
        color: Color(0x80000000),
        offset: Offset(0, 18),
        blurRadius: 40,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // Fade and scale are compositing-only (the two layers below are repaint boundaries); only the icon's own layer is redrawn,
    // and only while the star twinkles.
    return Opacity(
      opacity: frame.tileOpacity,
      child: Transform.scale(
        scale: frame.tileScale,
        child: SizedBox(
          key: const ValueKey('splash-tile'),
          width: 132,
          height: 132,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              RepaintBoundary(child: DecoratedBox(decoration: _shadow)),
              RepaintBoundary(
                child: ClipRRect(
                  borderRadius: _radius,
                  child: CustomPaint(
                    painter: AppIconPainter(twinkle: frame.twinkle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
