// The prayer-times screen (feature 014, FR-001..FR-024, contracts/ui.md). It reads and writes the `prayer.*` settings;
// the reminder scheduler sees every write through the settings table and replans the notifications by itself.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../reminders/reminder_scheduler.dart';
import '../theme.dart';
import '../wirds/wird_repository.dart';
import 'cities.dart';
import 'hijri.dart';
import 'location_port.dart';
import 'place_flow.dart';
import 'prayer_calc.dart';
import 'prayer_month_screen.dart';
import 'prayer_settings.dart';
import 'prayer_settings_sheet.dart';
import 'prayer_strings.dart';
import 'sun_arc.dart';

Future<String> _phoneZone() async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    try {
      return tz.local.name; // the zone the reminder service set at start
    } catch (_) {
      return 'UTC';
    }
  }
}

CityIndex? _sharedCities;
Future<CityIndex> _loadCities() async =>
    _sharedCities ??= await CityIndex.load(rootBundle);

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({
    super.key,
    this.location,
    this.loadCities,
    this.clock,
    this.phoneZone,
  });

  final LocationPort? location;
  final Future<CityIndex> Function()? loadCities;
  final DateTime Function()? clock;
  final Future<String> Function()? phoneZone;

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen>
    with WidgetsBindingObserver {
  late final LocationPort _location =
      widget.location ?? const ChannelLocationPort();
  late final Future<CityIndex> Function() _cities =
      widget.loadCities ?? _loadCities;
  late final DateTime Function() _clock = widget.clock ?? DateTime.now;
  late final Future<String> Function() _zone = widget.phoneZone ?? _phoneZone;

  PrayerSettings? _settings;
  String _phone = 'UTC';
  bool _exact = true;
  bool _notifAllowed = true;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's settings: the exact-alarm and notification permissions may have changed.
    if (state == AppLifecycleState.resumed) unawaited(_checkPermissions());
  }

  Future<void> _load() async {
    final repo = context.read<WirdRepository>();
    final phone = await _zone();
    final entries = await repo.prayerEntries();
    if (!mounted) return;
    setState(() {
      _phone = phone;
      _settings = PrayerSettings.read(entries, phoneZone: phone);
    });
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final service = context.read<Reminders?>()?.service;
    if (service == null) return;
    final exact = await service.exactAllowed();
    final allowed = await service.notificationsAllowed();
    if (!mounted) return;
    setState(() {
      _exact = exact;
      _notifAllowed = allowed;
    });
  }

  Future<void> _save(PrayerSettings s) async {
    setState(() => _settings = s);
    await context.read<WirdRepository>().setPrayerSettings(s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return Scaffold(
      key: const ValueKey('prayer-screen'),
      appBar: AppBar(title: const Text(kPrayerTitle)),
      body: SafeArea(
        top: false,
        child: s == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                children: [
                  if (!s.enabled)
                    _Off(onEnable: () => _save(s.copyWith(enabled: true)))
                  else if (s.place == null)
                    PlaceStep(
                      location: _location,
                      cities: _cities,
                      phoneZone: _zone,
                      onPlace: (p) => _save(s.copyWith(place: p)),
                    )
                  else
                    _day(context, s, s.place!),
                ],
              ),
      ),
    );
  }

  Widget _day(BuildContext context, PrayerSettings s, Place place) {
    final look = context.look;
    final now = _clock().toUtc();
    final today = PrayerCalc.localDate(now, place);
    final day = PrayerCalc.day(today, place, s);
    final (next, nextAt) = PrayerCalc.next(now, place, s);
    final nextIsToday = PrayerCalc.localDate(nextAt, place) == today;
    final zone = tz.getLocation(place.zone);
    final anyOn = s.notify.any((n) => n.mode != NotifyMode.off);
    String time(DateTime utc) {
      final l = tz.TZDateTime.from(utc, zone);
      return prayerTime(l.hour, l.minute);
    }

    final muted = TextStyle(color: look.textSecondary, fontSize: 14);
    final nextName = kPrayerNames[next.index];
    return Column(
      key: const ValueKey('prayer-day'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A wrap, not a row: with a large system font the button goes under the name instead of off the screen.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_outlined, size: 20, color: look.accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    place.name,
                    key: const ValueKey('prayer-place-name'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: look.text,
                    ),
                  ),
                ),
                // Design A: «تقريبًا» small and quiet after the name.
                if (place.source == PlaceSource.location) ...[
                  const SizedBox(width: 6),
                  Text(
                    kApprox,
                    style: TextStyle(fontSize: 13, color: look.textSecondary),
                  ),
                ],
              ],
            ),
            OutlinedButton(
              key: const ValueKey('place-change'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 44),
                foregroundColor: look.accent,
                side: BorderSide(color: look.line),
                shape: const StadiumBorder(),
              ),
              onPressed: () => _changePlace(s),
              child: const Text(kPlaceChange),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          children: [
            Text(gregorianDate(today), style: muted),
            Container(
              key: const ValueKey('prayer-hijri'),
              child: Text(
                HijriDate.fromGregorian(today).format(),
                style: muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          key: const ValueKey('prayer-next'),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          decoration: BoxDecoration(
            color: look.barFill,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: look.line),
          ),
          child: Column(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  key: const ValueKey('prayer-arc'),
                  height: 150,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: SunArcPainter(
                      marks: arcMarks(day),
                      sun: sunFraction(day, now),
                      next: next,
                      nextLabel: nextName,
                      direction: Directionality.of(context),
                      line: look.line,
                      dot: look.textSecondary,
                      accent: look.accent,
                    ),
                  ),
                ),
              ),
              // Design A: the lines sit 6 px apart; Cairo's own line height would spread them out.
              const SizedBox(height: 6),
              Text(kNextPrayer, style: muted.copyWith(height: 1.3)),
              const SizedBox(height: 6),
              Text(
                nextName,
                style: TextStyle(
                  fontFamily: kHeadingFont,
                  fontSize: 40,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: look.accent,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  countdown(nextAt.difference(now)),
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: look.text,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                atClock(time(nextAt)),
                style: muted.copyWith(fontSize: 15, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final p in Prayer.values)
          _row(
            context,
            s,
            p,
            time(day.utc[p]!),
            marked: nextIsToday && p == next,
            past: day.utc[p]!.isBefore(now),
          ),
        if (s.enabled && anyOn && !_exact)
          _Line(
            key: const ValueKey('exact-off'),
            text: kExactOff,
            action: kExactAllow,
            onAction: () =>
                context.read<Reminders?>()?.service.openExactSettings(),
          ),
        if (!_notifAllowed)
          _Line(
            key: const ValueKey('notif-off'),
            text: kNotifOff,
            action: kOpenSettings,
            onAction: () =>
                context.read<Reminders?>()?.service.requestPermission(),
          ),
        if (_zoneDiffers(place, now))
          _Line(
            key: const ValueKey('zone-differs'),
            text: kZoneDiffers,
            action: kPlaceLocate,
            onAction: () => _changePlace(s),
          ),
        if (day.highLatitude)
          _Line(key: const ValueKey('high-lat'), text: kHighLat),
        const SizedBox(height: 16),
        // Three equal icon tiles in one row (the owner's pick, 2026-11-26). The row takes the tallest tile's height,
        // so a label that wraps under a large system font keeps the three the same size.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _tile(
                  look,
                  key: 'prayer-month',
                  icon: Icons.calendar_month_outlined,
                  label: kMonthTable,
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => PrayerMonthScreen(
                        settings: s,
                        today: today,
                        now: now,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tile(
                  look,
                  key: 'prayer-settings',
                  icon: Icons.tune,
                  label: kAdjust,
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          PrayerSettingsPage(initial: s, onChanged: _save),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tile(
                  look,
                  key: 'prayer-test',
                  icon: Icons.notifications_outlined,
                  label: kTest,
                  onPressed: () => context.read<Reminders?>()?.service.showTest(
                    atPrayer(nextName),
                    kTestBody,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          children: [
            TextButton(
              key: const ValueKey('prayer-battery'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: look.textSecondary,
              ),
              onPressed: () => _battery(context),
              child: const Text(kBattery),
            ),
            TextButton(
              key: const ValueKey('prayer-disable'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: look.textSecondary,
              ),
              onPressed: () => _save(s.copyWith(enabled: false)),
              child: const Text(kPrayerDisable),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tile(
    AppLook look, {
    required String key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => OutlinedButton(
    key: ValueKey(key),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 72),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      foregroundColor: look.text,
      backgroundColor: look.barFill,
      side: BorderSide(color: look.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    onPressed: onPressed,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: look.accent),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  bool _zoneDiffers(Place place, DateTime now) {
    if (place.zone == _phone) return false;
    try {
      final a = tz.TZDateTime.from(
        now,
        tz.getLocation(place.zone),
      ).timeZoneOffset;
      final b = tz.TZDateTime.from(now, tz.getLocation(_phone)).timeZoneOffset;
      return a != b;
    } catch (_) {
      return false;
    }
  }

  Widget _row(
    BuildContext context,
    PrayerSettings s,
    Prayer p,
    String time, {
    required bool marked,
    required bool past,
  }) {
    final look = context.look;
    final name = kPrayerNames[p.index];
    final five = kFivePrayers.indexOf(p);
    final style = TextStyle(
      fontSize: 17,
      color: marked
          ? look.accent
          : past
          ? look.textSecondary
          : look.text,
      fontWeight: marked ? FontWeight.w700 : FontWeight.w500,
    );
    return Semantics(
      key: ValueKey('prayer-row-${p.name}'),
      container: true,
      value: marked ? kNextMark : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsetsDirectional.only(start: 14, end: 4),
        constraints: const BoxConstraints(minHeight: 52),
        // The next row is tinted with the accent; the others sit on the screen with no box of their own.
        decoration: BoxDecoration(
          color: marked
              ? Color.alphaBlend(
                  look.accent.withValues(alpha: 0.12),
                  look.background,
                )
              : look.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: marked ? look.accent : look.background,
            width: marked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(name, style: style)),
            // Shrinks, never cut, when a large system font makes the row too narrow.
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(time, style: style),
              ),
            ),
            if (five < 0)
              const SizedBox(width: 48)
            else
              _Bell(
                key: ValueKey('prayer-bell-${p.name}'),
                name: name,
                mode: s.notify[five].mode,
                color: marked ? look.accent : look.textSecondary,
                onTap: () {
                  final modes = NotifyMode.values;
                  final cur = s.notify[five];
                  final nextMode = modes[(cur.mode.index + 1) % modes.length];
                  final list = [...s.notify]
                    ..[five] = PrayerNotify(nextMode, cur.before);
                  unawaited(_save(s.copyWith(notify: list)));
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePlace(PrayerSettings s) async {
    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: PlaceStep(
              location: _location,
              cities: _cities,
              phoneZone: _zone,
              onPlace: (p) => Navigator.of(ctx).pop(p),
            ),
          ),
        ),
      ),
    );
    if (place != null && mounted) {
      await _save((_settings ?? s).copyWith(place: place));
    }
  }

  Future<void> _battery(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          kBatteryGuide,
          key: const ValueKey('battery-guide'),
          style: TextStyle(color: ctx.look.text),
        ),
      ),
    ),
  );
}

class _Off extends StatelessWidget {
  const _Off({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Column(
      key: const ValueKey('prayer-off'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(kPrayerIntro, style: TextStyle(fontSize: 16, color: look.text)),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('prayer-enable'),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: onEnable,
          child: const Text(kPrayerEnable),
        ),
      ],
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({
    super.key,
    required this.name,
    required this.mode,
    required this.color,
    required this.onTap,
  });

  final String name;
  final NotifyMode mode;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (mode) {
      NotifyMode.sound => (Icons.notifications_active, kNotifySound),
      NotifyMode.silent => (Icons.notifications_paused_outlined, kNotifySilent),
      NotifyMode.off => (Icons.notifications_off_outlined, kNotifyOff),
    };
    return IconButton(
      tooltip: '$name: $label',
      onPressed: onTap,
      icon: Icon(icon, color: color),
    );
  }
}

/// A one-line note with an optional button.
class _Line extends StatelessWidget {
  const _Line({super.key, required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: TextStyle(color: look.text)),
          if (action != null)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onAction,
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}
