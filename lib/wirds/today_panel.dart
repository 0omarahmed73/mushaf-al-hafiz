import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../look/wird_marker.dart';
import '../theme.dart';
import 'wird_repository.dart';

/// Second text colour on the ivory card of Emerald & Gold (the design's #2C4A3F). Screens that follow the chosen
/// look read `context.look.cardMuted` instead; this constant stays for the ones not yet moved over.
const Color kCardMuted = Color(0xFF2C4A3F);

/// A small rotated square in the wird's colour, the bullet of Emerald & Gold. New code uses [WirdMarker], which
/// is a dot in Night Reader.
class WirdDiamond extends StatelessWidget {
  const WirdDiamond({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: math.pi / 4,
    child: SizedBox(
      width: 10,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}

/// «ملخص اليوم»: one row per reading and qiyam wird with its portion, «من ص A إلى ص B», and either a
/// «تم» button or a tick once the portion is done (spec FR-032). With [onClose] it also shows a
/// header with a close button (used as the card that opens over the reader).
class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.entries,
    required this.onDone,
    this.onClose,
  });

  final List<TodayEntry> entries;
  final void Function(TodayEntry entry) onDone;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return DecoratedBox(
      key: const ValueKey('today-card'),
      decoration: BoxDecoration(
        color: look.cardFill,
        border: Border.all(
          color: look.cardBorderStrong,
          width: look.strongBorderWidth,
        ),
        borderRadius: BorderRadius.circular(look.cardRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          look.cardRadius - look.strongBorderWidth,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: look.cardInk),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClose != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ملخص اليوم',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: look.cardMuted,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('today-close'),
                        tooltip: 'إغلاق',
                        icon: const Icon(Icons.close, size: 20),
                        color: look.cardInk,
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('لا يوجد ورد للقراءة أو القيام اليوم'),
                ),
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0 || onClose != null)
                  Divider(height: 1, thickness: 1, color: look.cardDivider),
                _TodayRow(entry: entries[i], onDone: onDone),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.entry, required this.onDone});

  final TodayEntry entry;
  final void Function(TodayEntry entry) onDone;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final wird = entry.wird;
    return Padding(
      key: ValueKey('today-row-${wird.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          WirdMarker(color: Color(wird.color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wird.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'من ص ${entry.day.startPage} إلى ص ${entry.day.endPage}',
                  style: TextStyle(fontSize: 13, color: look.cardMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (entry.done)
            Row(
              key: ValueKey('today-tick-${wird.id}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 20, color: look.doneFill),
                const SizedBox(width: 6),
                Text(
                  'تم',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: look.doneFill,
                  ),
                ),
              ],
            )
          else
            FilledButton(
              key: ValueKey('today-done-${wird.id}'),
              onPressed: () => onDone(entry),
              style: FilledButton.styleFrom(
                backgroundColor: look.doneFill,
                foregroundColor: look.onDone,
                minimumSize: const Size(64, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(look.buttonRadius(10)),
                ),
              ),
              child: const Text('تم'),
            ),
        ],
      ),
    );
  }
}

/// The small pill in the reader's top bar: «ملخص اليوم» and how many portions are done. Tapping it
/// opens or closes [TodayCard] over the page. Draws nothing when there is no portion today.
class TodaySummaryChip extends StatelessWidget {
  const TodaySummaryChip({
    super.key,
    required this.entries,
    required this.open,
    required this.onTap,
  });

  final List<TodayEntry> entries;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final look = context.look;
    final done = entries.where((e) => e.done).length;
    return Semantics(
      button: true,
      label: 'ملخص اليوم، $done من ${entries.length}',
      child: InkWell(
        key: const ValueKey('today-chip'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: look.controlBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ملخص اليوم',
                  maxLines: 1,
                  style: TextStyle(fontSize: 12, color: look.text),
                ),
                const SizedBox(width: 6),
                Text(
                  '$done/${entries.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: look.accent,
                  ),
                ),
                Icon(
                  open ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: look.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small label on a card (type, «النشط», wird name). [filled] marks the active one: a dark green block in
/// Emerald & Gold, an outlined pill in the accent colour in Night Reader. Every other tag is an outline in the
/// card's own border colour.
class CardTag extends StatelessWidget {
  const CardTag(this.text, {super.key, this.filled = false});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final block = filled && !look.pillShapes;
    final Color border = filled
        ? (look.pillShapes ? look.cardBorderActive : look.doneFill)
        : look.cardBorder;
    final Color ink = filled
        ? (look.pillShapes ? look.cardBorderActive : look.onDone)
        : look.cardMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: block ? look.doneFill : null,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(look.tagRadius(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ink,
          ),
        ),
      ),
    );
  }
}
