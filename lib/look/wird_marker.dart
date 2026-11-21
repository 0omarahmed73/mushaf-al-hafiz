import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'contrast.dart';

/// The colour a wird's marker is drawn in. The owner's palette colour is stored as chosen and shown unchanged on
/// the light cards of Emerald & Gold; on a dark card (Night Reader) a colour that would be hard to see is
/// lightened, keeping its hue, until it reaches 3:1 against the card (spec FR-013).
Color markerColor(AppLook look, Color palette) {
  return look.darkCards ? liftToContrast(palette, look.cardFill, 3.0) : palette;
}

/// The small marker in front of a wird's name: a rotated square in Emerald & Gold, a round dot in Night Reader,
/// in [markerColor].
class WirdMarker extends StatelessWidget {
  const WirdMarker({super.key, required this.color});

  /// The wird's own colour from the palette.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final shown = markerColor(look, color);
    if (look.dotMarkers) {
      return SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(color: shown, shape: BoxShape.circle),
        ),
      );
    }
    return Transform.rotate(
      angle: math.pi / 4,
      child: SizedBox(
        width: 10,
        height: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: shown,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
