import 'package:flutter/widgets.dart';

import 'splash_screen.dart';

/// Shows the splash over [child] when the app starts (spec FR-007). The child is built from the first frame, so the app keeps
/// loading and drawing behind the splash and is already there when the splash fades; the gate needs only `Directionality` and
/// `MediaQuery` (for the splash only), which it provides itself, so it sits above `MaterialApp`.
///
/// [ready] completes when the app has finished its first loading (null means ready at once; a failure counts as finished, so a
/// splash never hangs on an error the app will show itself). [onFinished] is called once, after the splash is gone.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    this.ready,
    this.onFinished,
  });

  final Widget child;
  final Future<void>? ready;
  final VoidCallback? onFinished;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showing = true;
  late bool _ready = widget.ready == null;

  @override
  void initState() {
    super.initState();
    widget.ready?.then(
      (_) => _markReady(),
      onError: (Object _) => _markReady(),
    );
  }

  void _markReady() {
    if (mounted && !_ready) setState(() => _ready = true);
  }

  bool _finished = false;

  void _onGone() {
    if (!_showing) return;
    setState(() => _showing = false);
    // After the frame that removes the splash, so whatever [SplashGate.onFinished] starts finds the app alone on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _finished) return;
      _finished = true;
      widget.onFinished?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Under `runApp` nothing above this widget provides a MediaQuery, and the splash needs one for the text scale and the
    // reduce-motion setting; it is always built from the view, so the production path is the one every test runs. The app
    // itself is not wrapped: it builds its own.
    final splash = MediaQuery.fromView(
      view: View.of(context),
      child: SplashScreen(ready: _ready, onGone: _onGone),
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // While the splash shows, the app behind it can neither be touched nor be read by a screen reader.
          IgnorePointer(
            ignoring: _showing,
            child: ExcludeSemantics(excluding: _showing, child: widget.child),
          ),
          if (_showing) splash,
        ],
      ),
    );
  }
}
