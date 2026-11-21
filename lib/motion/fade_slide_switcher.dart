import 'package:material_ui/material_ui.dart';

import 'motion.dart';

/// Shows [child] and, when it appears or goes (null), fades it with a vertical slide of [slide] dp (negative: from above).
///
/// One child at any time: a child that goes stays in the tree only for the length of its fade, ignores pointers and is
/// hidden from screen readers while it leaves, and is then removed (a test that taps and pumps 300 ms finds it gone).
/// The widget keeps its own place in the tree for as long as it lives, so what is inside it is never rebuilt by a
/// different arrangement of its parents. A change that did not come from the reader (a rotation, a resume) passes
/// `animate: false` and happens at once; so does every change while the phone's «remove animations» is on
/// (contracts/ui.md, rules 1 and 2).
class FadeSlideSwitcher extends StatefulWidget {
  const FadeSlideSwitcher({
    super.key,
    required this.child,
    required this.slide,
    this.animate = true,
    this.durationIn = Motion.barIn,
    this.durationOut = Motion.barOut,
  });

  /// The content, or null for nothing. Give a new non-null child freely: only null <-> non-null is animated.
  final Widget? child;

  /// Distance in dp; negative slides in from above and out upwards.
  final double slide;

  /// False makes this change instant (a rotation, a resume).
  final bool animate;
  final Duration durationIn;
  final Duration durationOut;

  @override
  State<FadeSlideSwitcher> createState() => _FadeSlideSwitcherState();
}

class _FadeSlideSwitcherState extends State<FadeSlideSwitcher>
    with SingleTickerProviderStateMixin {
  // Made in initState, not lazily: a lazy controller would first be read after the child appeared and start at 1.
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  /// The last non-null child: what is drawn while it leaves.
  Widget? _last;

  @override
  void initState() {
    super.initState();
    _last = widget.child;
    _controller = AnimationController(
      vsync: this,
      duration: widget.durationIn,
      reverseDuration: widget.durationOut,
      value: widget.child == null ? 0 : 1,
    )..addStatusListener(_onStatus);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Motion.enter,
      reverseCurve: Motion.exit,
    );
  }

  @override
  void didUpdateWidget(FadeSlideSwitcher old) {
    super.didUpdateWidget(old);
    _controller.duration = widget.durationIn;
    _controller.reverseDuration = widget.durationOut;
    final now = widget.child;
    if (now != null) _last = now;
    if ((old.child == null) == (now == null)) return;
    final instant = !widget.animate || Motion.reduced(context);
    if (now != null) {
      if (instant) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    } else if (instant) {
      _controller.value = 0;
      _last = null;
    } else {
      _controller.reverse();
    }
  }

  void _onStatus(AnimationStatus status) {
    // The leaving child is dropped when its fade ends (and only if nothing came back meanwhile).
    if (status == AnimationStatus.dismissed &&
        widget.child == null &&
        _last != null &&
        mounted) {
      setState(() => _last = null);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _last;
    if (child == null) return const SizedBox.shrink();
    final leaving = widget.child == null;
    return IgnorePointer(
      ignoring: leaving,
      child: ExcludeSemantics(
        excluding: leaving,
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, widget.slide * (1 - _curve.value)),
            child: FadeTransition(opacity: _curve, child: child),
          ),
          child: child,
        ),
      ),
    );
  }
}
