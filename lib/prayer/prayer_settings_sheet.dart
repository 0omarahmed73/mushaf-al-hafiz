// Adjusting the calculation and the notifications (feature 014, US3, FR-007..FR-009, FR-015, FR-017, contracts/ui.md).
// Every change is saved at once through [onChanged]; the reminder scheduler replans by itself.
import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'prayer_calc.dart';
import 'prayer_settings.dart';
import 'prayer_strings.dart';

class PrayerSettingsPage extends StatefulWidget {
  const PrayerSettingsPage({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final PrayerSettings initial;
  final ValueChanged<PrayerSettings> onChanged;

  @override
  State<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends State<PrayerSettingsPage> {
  late PrayerSettings _s = widget.initial;

  void _set(PrayerSettings s) {
    setState(() => _s = s);
    widget.onChanged(s);
  }

  String _methodName() {
    if (_s.method != 'auto') return kMethodNames[_s.method]!;
    final place = _s.place;
    return place == null
        ? kMethodAuto
        : '$kMethodAuto: ${kMethodNames[PrayerCalc.methodFor(place.country)]}';
  }

  Future<void> _pickMethod() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final k in ['auto', ...kPrayerMethods])
                ListTile(
                  key: ValueKey('method-$k'),
                  minTileHeight: 48,
                  selected: _s.method == k,
                  title: Text(k == 'auto' ? kMethodAuto : kMethodNames[k]!),
                  onTap: () => Navigator.of(ctx).pop(k),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) _set(_s.copyWith(method: picked));
  }

  Future<void> _pickBefore(int five) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in kBeforeChoices)
                ListTile(
                  key: ValueKey('before-$m'),
                  minTileHeight: 48,
                  selected: _s.notify[five].before == m,
                  title: Text(m == 0 ? kBeforeOff : minutesLabel(m)),
                  onTap: () => Navigator.of(ctx).pop(m),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    final list = [..._s.notify]
      ..[five] = PrayerNotify(_s.notify[five].mode, picked);
    _set(_s.copyWith(notify: list));
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final head = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: look.textSecondary,
    );
    final body = TextStyle(color: look.text);
    return Scaffold(
      key: const ValueKey('prayer-settings-sheet'),
      appBar: AppBar(title: const Text(kAdjust)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
          children: [
            ListTile(
              key: const ValueKey('set-method'),
              contentPadding: EdgeInsets.zero,
              minTileHeight: 48,
              title: Text(kMethod, style: body),
              subtitle: Text(
                _methodName(),
                style: TextStyle(color: look.textSecondary),
              ),
              onTap: _pickMethod,
            ),
            const SizedBox(height: 8),
            Text(kAsr, style: head),
            Wrap(
              spacing: 8,
              children: [
                for (final (rule, label) in [
                  (AsrRule.standard, kAsrStandard),
                  (AsrRule.hanafi, kAsrHanafi),
                ])
                  ChoiceChip(
                    key: ValueKey('set-asr-${rule.name}'),
                    label: Text(label),
                    selected: _s.asr == rule,
                    onSelected: (_) => _set(_s.copyWith(asr: rule)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(kOffsets, style: head),
            for (final p in Prayer.values) _offsetRow(p, body),
            const SizedBox(height: 16),
            Text(kNotifySection, style: head),
            for (var i = 0; i < kFivePrayers.length; i++) _notifyRow(i, body),
          ],
        ),
      ),
    );
  }

  Widget _offsetRow(Prayer p, TextStyle body) {
    final v = _s.offsets[p.index];
    void step(int d) {
      final list = [..._s.offsets]..[p.index] = (v + d).clamp(-30, 30);
      _set(_s.copyWith(offsets: list));
    }

    return Row(
      children: [
        Expanded(child: Text(kPrayerNames[p.index], style: body)),
        IconButton(
          key: ValueKey('set-offset-${p.name}-minus'),
          tooltip: '${kPrayerNames[p.index]} −',
          onPressed: v <= -30 ? null : () => step(-1),
          icon: const Icon(Icons.remove),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(offsetLabel(v), style: body),
          ),
        ),
        IconButton(
          key: ValueKey('set-offset-${p.name}-plus'),
          tooltip: '${kPrayerNames[p.index]} +',
          onPressed: v >= 30 ? null : () => step(1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _notifyRow(int five, TextStyle body) {
    final p = kFivePrayers[five];
    final n = _s.notify[five];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kPrayerNames[p.index],
            style: body.copyWith(fontWeight: FontWeight.w600),
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (mode, label) in [
                (NotifyMode.sound, kNotifySound),
                (NotifyMode.silent, kNotifySilent),
                (NotifyMode.off, kNotifyOff),
              ])
                ChoiceChip(
                  key: ValueKey('set-notify-${p.name}-${mode.name}'),
                  label: Text(label),
                  selected: n.mode == mode,
                  onSelected: (_) {
                    final list = [..._s.notify]
                      ..[five] = PrayerNotify(mode, n.before);
                    _set(_s.copyWith(notify: list));
                  },
                ),
              TextButton(
                key: ValueKey('set-before-${p.name}'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => _pickBefore(five),
                child: Text(
                  '$kBefore: ${n.before == 0 ? kBeforeOff : minutesLabel(n.before)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
