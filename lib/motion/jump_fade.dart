import 'package:material_ui/material_ui.dart';

import 'motion.dart';

/// Tells a [JumpFade] that the page under it was just replaced by a jump (index, go-to-page, bookmark, notification,
/// another wird). Nothing plays until [play] is called, so the first frame of a start never fades.
class JumpFadeController extends ChangeNotifier {
  void play() => notifyListeners();
}

/// Fades its child in from [from] to 1 over [Motion.jump] each time [controller] plays: a soft arrival of the new page,
/// no slide and no pages built in between (spec FR-010). A second play in the middle starts from the current opacity's
/// start again; [Duration.zero] while the phone's «remove animations» is on. At rest the child is not wrapped in a layer.
class JumpFade extends StatefulWidget {
  const JumpFade({
    super.key,
    required this.controller,
    required this.child,
    this.from = 0.35,
  });

  final JumpFadeController controller;
  final Widget child;
  final double from;

  @override
  State<JumpFade> createState() => _JumpFadeState();
}

class _JumpFadeState extends State<JumpFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: Motion.jump,
    value: 1,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: widget.from,
    end: 1,
  ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_play);
  }

  @override
  void didUpdateWidget(JumpFade old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_play);
      widget.controller.addListener(_play);
    }
  }

  void _play() {
    if (!mounted) return;
    if (Motion.reduced(context)) {
      _animation.value = 1;
    } else {
      _animation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_play);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
