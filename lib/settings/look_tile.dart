import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../look/look_choice.dart';
import '../look/look_settings.dart';
import '../motion/look_fade.dart';
import '../theme.dart';

/// «المظهر» in Settings: the two looks side by side (stacked on a narrow window or with a large system font), each
/// with a small sample of its colours, the chosen one marked with a check and an outline. A tap saves the choice at
/// once and the whole app changes (spec FR-001, FR-003). Shows nothing when the app has no look setting (tests that
/// do not need it).
class LookTile extends StatelessWidget {
  const LookTile({super.key});

  static const String kTitle = 'المظهر';
  static const String kEmerald = 'زمردي وذهبي';
  static const String kNight = 'القارئ الليلي';
  static const String kNote =
      'يُطبَّق على التطبيق كله وعلى الصورة وملف PDF اللذين تشاركهما';

  @override
  Widget build(BuildContext context) {
    final setting = context.watch<AppLookSettings?>();
    if (setting == null) return const SizedBox.shrink();
    final look = context.look;
    final options = [
      _LookOption(
        choice: LookChoice.emerald,
        name: kEmerald,
        selected: setting.choice == LookChoice.emerald,
        onTap: () =>
            LookFade.around(context, () => setting.set(LookChoice.emerald)),
      ),
      _LookOption(
        choice: LookChoice.night,
        name: kNight,
        selected: setting.choice == LookChoice.night,
        onTap: () =>
            LookFade.around(context, () => setting.set(LookChoice.night)),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(
            kTitle,
            key: const ValueKey('look-title'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: look.textSecondary,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, box) {
            // Two options need room: below 300 dp wide, or with a large system font, they stack.
            final stacked =
                box.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(15) > 20;
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [options[0], const SizedBox(height: 10), options[1]],
              );
            }
            // IntrinsicHeight: the two cards are as tall as the taller one, also inside a scroll view.
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: options[0]),
                  const SizedBox(width: 12),
                  Expanded(child: options[1]),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
          child: Text(
            kNote,
            key: const ValueKey('look-note'),
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: look.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LookOption extends StatelessWidget {
  const _LookOption({
    required this.choice,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final LookChoice choice;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final radius = BorderRadius.circular(look.cardRadius);
    return Semantics(
      key: ValueKey('look-${choice.name}'),
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? look.accent : look.controlBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _Swatch(
                    key: ValueKey('look-swatch-${choice.name}'),
                    look: choice.look,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: look.text,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, size: 22, color: look.accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small sample of a look: its background with a card and an accent dot on it, edged by a hairline so a near-black
/// sample can be seen on a near-black screen.
class _Swatch extends StatelessWidget {
  const _Swatch({super.key, required this.look});

  final AppLook look;

  @override
  Widget build(BuildContext context) {
    final edge = context.look.controlBorder;
    return SizedBox(
      width: 40,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: edge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: look.cardFill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: look.accent,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 8, height: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
