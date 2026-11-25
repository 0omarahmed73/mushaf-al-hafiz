import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../mushaf/mushaf_page.dart' show kBasmallah, kQuranFont;
import '../theme.dart';
import 'large_ayah_settings.dart';
import 'large_ayah_strings.dart';
import 'page_screens.dart';

/// The Settings tile of the large-ayah view (feature 015, FR-017, contracts/ui.md): the switch, and while it is on the
/// number of ayat per screen and the size. Turning it on goes back to the reader, which then shows the view.
class LargeAyahTile extends StatelessWidget {
  const LargeAyahTile({super.key});

  @override
  Widget build(BuildContext context) {
    final setting = context.watch<LargeAyahSettings?>();
    if (setting == null) return const SizedBox.shrink();
    final look = context.look;
    final label = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: look.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const ValueKey('large-ayah-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text(LargeAyahStrings.title),
          subtitle: const Text(LargeAyahStrings.subtitle),
          value: setting.on,
          onChanged: (on) async {
            await setting.setOn(on);
            if (on && context.mounted) Navigator.of(context).maybePop();
          },
        ),
        if (setting.on) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text(LargeAyahStrings.countTitle, style: label),
          ),
          _Choices(
            prefix: 'large-count',
            labels: LargeAyahStrings.counts,
            selected: setting.count,
            onSelected: setting.setCount,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(LargeAyahStrings.sizeTitle, style: label),
          ),
          _Choices(
            prefix: 'large-size',
            labels: LargeAyahStrings.sizes,
            selected: setting.sizeStep,
            onSelected: setting.setSizeStep,
          ),
          _Preview(factor: setting.factor),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.prefix, required this.labels, required this.selected, required this.onSelected});

  final String prefix;
  final List<String> labels;
  final int selected;
  final Future<void> Function(int) onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (var i = 1; i <= labels.length; i++)
        ConstrainedBox(
          key: ValueKey('$prefix-$i'),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            widthFactor: 1,
            child: ChoiceChip(
              label: Text(labels[i - 1]),
              selected: selected == i,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (_) => onSelected(i),
            ),
          ),
        ),
    ],
  );
}

/// The basmala at the chosen size, as a preview of the view's letters on this phone.
class _Preview extends StatelessWidget {
  const _Preview({required this.factor});

  final double factor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final g = LargeGeometry(width: size.width, height: size.height, factor: factor);
    return MediaQuery.withNoTextScaling(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          kBasmallah,
          key: const ValueKey('large-size-preview'),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kQuranFont, fontSize: g.fontSize * 0.7, height: 1.4, color: context.look.text),
        ),
      ),
    );
  }
}
