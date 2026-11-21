import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import 'motion.dart';

/// Wraps everything the app draws, above the navigator, so a look change fades over any open screen (Settings included)
/// (feature 010, FR-012; research D6 and D11).
///
/// The theme never interpolates between Emerald & Gold and Night Reader (they differ in shape, feature 004): the new look is
/// in place on the first frame. [LookFade.around] only lays the picture of the old look over it and fades that picture out
/// over [Motion.look]. Nothing here changes a setting or a colour; with no host above, or with the phone's «remove
/// animations» on, [LookFade.around] is just the change.
class LookFadeHost extends StatefulWidget {
  const LookFadeHost({super.key, required this.child});

  final Widget child;

  @override
  State<LookFadeHost> createState() => _LookFadeHostState();
}

class _LookFadeHostState extends State<LookFadeHost>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundary = GlobalKey();
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  ui.Image? _picture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Motion.look);
    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _picture?.dispose();
    super.dispose();
  }

  /// The picture of what is drawn now; null when it cannot be taken (then the change is simply instant).
  Future<ui.Image?> _capture() async {
    final box = _boundary.currentContext?.findRenderObject();
    if (box is! RenderRepaintBoundary) return null;
    try {
      return await box.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } catch (_) {
      return null;
    }
  }

  /// Lays [image] over the app at full opacity, in the same frame as the change that follows.
  void _hold(ui.Image image) {
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _picture?.dispose();
      _picture = image;
    });
    _controller.value = 0;
  }

  /// Fades the held picture out and removes it.
  Future<void> _release() async {
    if (!mounted || _picture == null) return;
    try {
      await _controller.forward(from: 0);
    } on TickerCanceled {
      // Disposed in the middle: nothing is left to show.
    }
    if (!mounted) return;
    setState(() {
      _picture?.dispose();
      _picture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final picture = _picture;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (picture != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: FadeTransition(
                  opacity: _opacity,
                  child: RawImage(image: picture, fit: BoxFit.fill),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Runs a look change so that the old look fades out over the new one.
abstract final class LookFade {
  /// Runs [change] (the call that sets the look). The picture of the screen is taken first and laid over it, so the new
  /// look never shows for a frame without it; once [change] is done the picture fades out over [Motion.look]. Without a
  /// [LookFadeHost] above [context], with «remove animations» on, or when the picture cannot be taken, it is [change]
  /// alone. The returned future completes when [change] is done, not when the fade is.
  static Future<void> around(
    BuildContext context,
    Future<void> Function() change,
  ) async {
    final host = context.findAncestorStateOfType<_LookFadeHostState>();
    if (host == null || Motion.reduced(context)) {
      await change();
      return;
    }
    final picture = await host._capture();
    if (picture == null) {
      await change();
      return;
    }
    host._hold(picture);
    try {
      await change();
    } finally {
      // Fades whether the change succeeded or not, so a picture is never left over the app.
      host._release();
    }
  }
}
