import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../ayah/ui/reading_text.dart';
import '../theme.dart';
import 'text_size.dart';
import 'text_size_settings.dart';

/// «حجم الخط» in Settings: a slider over the eight sizes, the chosen size in percent, a preview of the reading
/// texts at that size, a note on where it applies, and «الحجم الافتراضي». Every move is saved at once (spec
/// FR-001..FR-004). Shows nothing when the app has no size setting (tests that do not need it).
class TextSizeTile extends StatelessWidget {
  const TextSizeTile({super.key});

  static const String kPreviewArabic =
      'هذه فقرة تجريبية تُعرض بحجم نص التفسير، لترى الحجم قبل أن تعود إلى القراءة.';
  static const String kPreviewEnglish =
      'This is a sample sentence shown at the size of the translation.';
  static const String kNote =
      'يُطبَّق على التفسير والترجمة ومعاني الكلمات وعلى صفحة المصحف';

  @override
  Widget build(BuildContext context) {
    final setting = context.watch<TextSizeSettings?>();
    if (setting == null) return const SizedBox.shrink();
    final look = context.look;
    final percent = setting.percent;
    final first = TextSize.steps.first, last = TextSize.steps.last;
    // Where the 100% stop sits along the track, counted from the start side (the right in Arabic).
    final defaultAt =
        (TextSize.defaultPercent - first) / (last - first) * 2 - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 22, 4, 0),
          child: _TitleRow(),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: look.accent,
            inactiveTrackColor: look.line,
            thumbColor: look.accent,
            overlayColor: look.accent.withValues(alpha: 0.18),
            activeTickMarkColor: look.background,
            inactiveTickMarkColor: look.ring,
            // The size is written next to the title, so no bubble over the thumb.
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: SizedBox(
            height: 56,
            child: Slider(
              key: const ValueKey('text-size-slider'),
              min: first.toDouble(),
              max: last.toDouble(),
              divisions: TextSize.steps.length - 1,
              value: percent.toDouble(),
              // Read by screen readers as the name of the slider; the value is read as «120%».
              label: 'حجم الخط',
              semanticFormatterCallback: (v) => '${v.round()}%',
              onChanged: (v) => setting.set(v.round()),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: AlignmentDirectional(defaultAt, 0),
            child: Text(
              '100%',
              key: const ValueKey('text-size-default-mark'),
              style: TextStyle(fontSize: 11, color: look.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _Preview(),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
          child: Text(
            kNote,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: look.textSecondary,
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const ValueKey('text-size-reset'),
            onPressed: setting.isDefault ? null : setting.reset,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: look.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'الحجم الافتراضي',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

/// The title and the chosen size, on one line.
class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    final percent = context.watch<TextSizeSettings?>()?.percent ?? 100;
    final look = context.look;
    return Row(
      children: [
        Expanded(
          child: Text(
            'حجم الخط',
            key: const ValueKey('text-size-title'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: look.text,
            ),
          ),
        ),
        Text(
          '$percent%',
          key: const ValueKey('text-size-value'),
          style: TextStyle(fontSize: 16, color: look.accent),
        ),
      ],
    );
  }
}

/// A card of the look (ivory in Emerald & Gold) with the two reading styles at the chosen size, built with the same styles and the same cap
/// as the ayah menu so what is shown here is what the menu shows.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: look.cardFill,
        border: Border.all(color: look.cardBorderStrong),
        borderRadius: BorderRadius.circular(look.rowRadius(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ReadingScope(
          child: Builder(
            builder: (context) {
              final styles = ReadingScope.of(context);
              return DefaultTextStyle.merge(
                style: TextStyle(color: look.cardInk),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معاينة',
                      key: const ValueKey('text-size-preview'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: look.cardMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TextSizeTile.kPreviewArabic,
                      key: const ValueKey('text-size-preview-ar'),
                      style: styles.arabic,
                    ),
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        TextSizeTile.kPreviewEnglish,
                        key: const ValueKey('text-size-preview-en'),
                        textAlign: TextAlign.left,
                        style: styles.english,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
