import 'package:material_ui/material_ui.dart';

import 'motion.dart';

/// Shows [child] and, whenever [value] changes, shows the new child at once and fades it in from 0 over [duration] (and
/// grows it from [fromScale] to 1 when that is below 1). One child at any time: nothing of the old value stays in the tree
/// (unlike an `AnimatedSwitcher`), so a test or a screen reader never sees two bookmark icons or two wird names.
/// The first build shows the child as it is, with no fade. [Duration.zero] while the phone's «remove animations» is on.
class FadeInOnChange extends StatefulWidget {
  const FadeInOnChange({
    super.key,
    required this.value,
    required this.child,
    this.duration = Motion.swap,
    this.fromScale = 1.0,
  });

  final Object? value;
  final Widget child;
  final Duration duration;
  final double fromScale;

  @override
  State<FadeInOnChange> createState() => _FadeInOnChangeState();
}

class _FadeInOnChangeState extends State<FadeInOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Motion.enter);
  }

  @override
  void didUpdateWidget(FadeInOnChange old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    _controller.duration = widget.duration;
    if (Motion.reduced(context) || widget.duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
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
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        final scale = widget.fromScale + (1 - widget.fromScale) * t;
        Widget result = FadeTransition(opacity: _curve, child: child);
        if (widget.fromScale != 1.0) {
          result = Transform.scale(scale: scale, child: result);
        }
        return result;
      },
    );
  }
}
