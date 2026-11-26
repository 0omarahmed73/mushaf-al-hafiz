// The month's timetable (feature 014, US4, FR-012, contracts/ui.md) as design C «أيام تتفتح», the owner's pick on
// 2026-11-26: month chips, a card per day with its Fajr and Maghrib, today open with all six times, a tap opens or
// closes any day, and the Islamic days named on their card.
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

import '../theme.dart';
import 'hijri.dart';
import 'islamic_events.dart';
import 'prayer_calc.dart';
import 'prayer_settings.dart';
import 'prayer_strings.dart';

class PrayerMonthScreen extends StatefulWidget {
  const PrayerMonthScreen({
    super.key,
    required this.settings,
    required this.today,
    this.now,
  });

  final PrayerSettings settings;

  /// Today's local date at the place.
  final DateTime today;

  /// The moment the table was opened (UTC), to mark today's next prayer; null marks none.
  final DateTime? now;

  @override
  State<PrayerMonthScreen> createState() => _PrayerMonthScreenState();
}

class _PrayerMonthScreenState extends State<PrayerMonthScreen> {
  late DateTime _month = DateTime(widget.today.year, widget.today.month);
  late Set<int> _openDays = _defaultOpen();
  final GlobalKey _todayKey = GlobalKey();

  bool get _thisMonth =>
      _month.year == widget.today.year && _month.month == widget.today.month;

  Set<int> _defaultOpen() => _thisMonth ? {widget.today.day} : {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showToday());
  }

  void _showToday() {
    final ctx = _todayKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.1);
  }

  void _move(int d) => setState(() {
    _month = DateTime(_month.year, _month.month + d);
    _openDays = _defaultOpen();
  });

  void _toggle(int day) => setState(
    () => _openDays.contains(day) ? _openDays.remove(day) : _openDays.add(day),
  );

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final prev = DateTime(_month.year, _month.month - 1);
    final next = DateTime(_month.year, _month.month + 1);
    final next2 = DateTime(_month.year, _month.month + 2);
    return Scaffold(
      key: const ValueKey('prayer-month-screen'),
      appBar: AppBar(title: const Text(kMonthTable)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Design C: one row of four chips (the month before, this month, the next two), scrolling sideways when
            // a large system font makes them wider than the screen.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  _chip(
                    look,
                    key: 'month-prev',
                    label: monthName(prev.month),
                    tooltip: kPrevMonth,
                    onTap: () => _move(-1),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    key: const ValueKey('month-current'),
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: look.primaryFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      monthTitle(_month.year, _month.month),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: look.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    look,
                    key: 'month-next',
                    label: monthName(next.month),
                    tooltip: kNextMonth,
                    onTap: () => _move(1),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    look,
                    key: 'month-next2',
                    label: monthName(next2.month),
                    tooltip: monthTitle(next2.year, next2.month),
                    onTap: () => _move(2),
                  ),
                ],
              ),
            ),
            Expanded(
              // Every day is built (a month is at most 31 cards), so today can be scrolled to when the table opens.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: Column(
                  children: [for (var d = 1; d <= days; d++) _day(context, d)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    AppLook look, {
    required String key,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) => Tooltip(
    message: tooltip,
    child: OutlinedButton(
      key: ValueKey(key),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 40),
        fixedSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        foregroundColor: look.textSecondary,
        side: BorderSide(color: look.line),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: kUiFont,
          fontSize: 14,
          height: 1.2,
        ),
      ),
      onPressed: onTap,
      child: Text(label),
    ),
  );

  Widget _day(BuildContext context, int d) {
    final look = context.look;
    final s = widget.settings;
    final place = s.place!;
    final zone = tz.getLocation(place.zone);
    String time(DateTime utc) {
      final l = tz.TZDateTime.from(utc, zone);
      return prayerTime(l.hour, l.minute);
    }

    final date = DateTime(_month.year, _month.month, d);
    final t = PrayerCalc.day(date, place, s);
    final isToday = date == widget.today;
    final past = date.isBefore(widget.today);
    final open = _openDays.contains(d);
    final hijri = HijriDate.fromGregorian(date);
    final event = islamicEvent(hijri);
    final title =
        '${isToday ? '$kToday · ' : ''}${indic(hijri.day)} ${kHijriMonths[hijri.month - 1]}';
    final ink = past ? look.textSecondary : look.text;

    Prayer? nextPrayer;
    final now = widget.now;
    if (isToday && now != null) {
      final (p, at) = PrayerCalc.next(now, place, s);
      if (PrayerCalc.localDate(at, place) == date) nextPrayer = p;
    }

    return Container(
      key: isToday ? _todayKey : null,
      margin: const EdgeInsets.only(bottom: 6),
      child: Container(
        key: ValueKey('month-day-$d'),
        decoration: BoxDecoration(
          color: look.barFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isToday ? look.accent : look.line,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: ValueKey('month-open-$d'),
              borderRadius: BorderRadius.circular(18),
              onTap: () => _toggle(d),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _badge(look, date, isToday: isToday, past: past),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                color: isToday ? look.accent : ink,
                              ),
                            ),
                            if (event != null)
                              Row(
                                key: ValueKey('month-event-$d'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: look.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      event,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.3,
                                        fontWeight: FontWeight.w700,
                                        color: look.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (!open)
                              Text(
                                monthSummary(
                                  time(t.utc[Prayer.fajr]!),
                                  time(t.utc[Prayer.maghrib]!),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color: look.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        open ? Icons.expand_less : Icons.expand_more,
                        color: isToday ? look.accent : look.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (open)
              Padding(
                key: ValueKey('month-times-$d'),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: Column(
                  children: [
                    for (final row in [
                      Prayer.values.sublist(0, 3),
                      Prayer.values.sublist(3),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final p in row) ...[
                                if (p != row.first) const SizedBox(width: 6),
                                Expanded(
                                  child: _cell(
                                    look,
                                    d,
                                    p,
                                    time(t.utc[p]!),
                                    next: p == nextPrayer,
                                    gone:
                                        isToday &&
                                        now != null &&
                                        t.utc[p]!.isBefore(now),
                                    dim: past,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(
    AppLook look,
    DateTime date, {
    required bool isToday,
    required bool past,
  }) {
    final color = isToday
        ? look.onPrimary
        : past
        ? look.textSecondary
        : look.text;
    return Container(
      key: isToday ? const ValueKey('month-today') : null,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isToday ? look.primaryFill : look.barFill,
        borderRadius: BorderRadius.circular(14),
        border: isToday ? null : Border.all(color: look.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            indic(date.day),
            style: TextStyle(
              fontSize: 17,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            weekdayName(date),
            style: TextStyle(fontSize: 10, height: 1.2, color: color),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    AppLook look,
    int d,
    Prayer p,
    String time, {
    required bool next,
    required bool gone,
    required bool dim,
  }) {
    final ink = next
        ? look.accent
        : gone || dim
        ? look.textSecondary
        : look.text;
    return Container(
      key: ValueKey('month-time-$d-${p.name}'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: next
            ? Color.alphaBlend(
                look.accent.withValues(alpha: 0.12),
                look.background,
              )
            : look.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: next ? look.accent : look.line,
          width: next ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kPrayerNames[p.index],
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: next ? look.accent : look.textSecondary,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
