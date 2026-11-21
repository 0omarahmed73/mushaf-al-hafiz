import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../digits.dart';
import '../look/contrast.dart';
import '../look/wird_marker.dart';
import '../theme.dart';
import 'portion.dart';
import 'wird_palette.dart';
import 'wird_repository.dart';

enum _Amount { pagesPerDay, targetDate }

/// Adds a wird, or edits [wird]: name, type, start page, amount (pages per day or a target date),
/// reminder and colour (spec FR-021, FR-022, FR-025, FR-027). Pops `true` once saved.
class WirdFormScreen extends StatefulWidget {
  const WirdFormScreen({super.key, this.wird, this.colorIndex = 0});

  /// The wird being edited; null for a new one.
  final Wird? wird;

  /// Palette entry a new wird starts with.
  final int colorIndex;

  @override
  State<WirdFormScreen> createState() => _WirdFormScreenState();
}

class _WirdFormScreenState extends State<WirdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _startPage;
  late final TextEditingController _pages;
  late WirdType _type;
  late _Amount _amount;
  DateTime? _target;
  bool _targetMissing = false;
  late bool _notify;
  bool _notifyTouched = false;
  late int _minutes;
  late int _color;
  bool _saving = false;

  static int _defaultPagesFor(WirdType type) =>
      type == WirdType.qiyam ? 2 : kDefaultDailyPages;

  @override
  void initState() {
    super.initState();
    final w = widget.wird;
    _type = w?.type ?? WirdType.reading;
    _name = TextEditingController(text: w?.name ?? '');
    _startPage = TextEditingController(text: '${w?.currentPage ?? 1}');
    _amount = (w != null && w.dailyPages == null && w.targetDate != null)
        ? _Amount.targetDate
        : _Amount.pagesPerDay;
    _pages = TextEditingController(
      text: '${w?.dailyPages ?? _defaultPagesFor(_type)}',
    );
    _target = w?.targetDate;
    _notify = w?.notifyEnabled ?? (_type == WirdType.reading);
    _minutes = w?.notifyMinutes ?? WirdRepository.defaultReminderMinutes;
    _color = w?.color ?? wirdColorAt(widget.colorIndex);
  }

  @override
  void dispose() {
    _name.dispose();
    _startPage.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _setType(WirdType type) {
    setState(() {
      // Keep what the user typed; only follow the default of the old type while it is untouched.
      if (_pages.text.trim() == '${_defaultPagesFor(_type)}') {
        _pages.text = '${_defaultPagesFor(type)}';
      }
      // A new wird's reminder follows its type until the user decides (FR-025).
      if (widget.wird == null && !_notifyTouched) {
        _notify = type == WirdType.reading;
      }
      _type = type;
    });
  }

  static String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
    );
    if (picked != null) {
      setState(() => _minutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: (_target != null && !_target!.isBefore(first))
          ? _target!
          : first.add(const Duration(days: 30)),
      firstDate: first,
      lastDate: DateTime(first.year + 5, first.month, first.day),
    );
    if (picked != null) {
      setState(() {
        _target = picked;
        _targetMissing = false;
      });
    }
  }

  String? _validateName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'أدخل اسم الورد' : null;

  String? _validateStartPage(String? v) {
    final n = int.tryParse((v ?? '').trim());
    return (n == null || n < 1 || n > kLastPage)
        ? 'أدخل رقماً من 1 إلى 604'
        : null;
  }

  String? _validatePages(String? v) {
    if (_amount != _Amount.pagesPerDay) return null;
    final n = int.tryParse((v ?? '').trim());
    return (n == null || n < 1) ? 'أدخل عدداً لا يقل عن 1' : null;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    final dateMissing = _amount == _Amount.targetDate && _target == null;
    setState(() => _targetMissing = dateMissing);
    if (!valid || dateMissing || _saving) return;
    setState(() => _saving = true);
    final draft = WirdDraft(
      name: _name.text.trim(),
      type: _type,
      startPage: int.parse(_startPage.text.trim()),
      dailyPages: _amount == _Amount.pagesPerDay
          ? int.parse(_pages.text.trim())
          : null,
      targetDate: _amount == _Amount.targetDate ? _target : null,
      notifyEnabled: _notify,
      notifyMinutes: _notify ? _minutes : null,
      color: _color,
    );
    final repo = context.read<WirdRepository>();
    final wird = widget.wird;
    if (wird == null) {
      await repo.create(draft);
    } else {
      await repo.update(wird.id, draft);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final editing = widget.wird != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'تعديل الورد' : 'ورد جديد')),
      // Safe space at the bottom: the content stops above the system navigation bar and leaves
      // room under the save button.
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            children: [
              TextFormField(
                key: const ValueKey('wird-name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'اسم الورد',
                  counterText: '',
                ),
                validator: _validateName,
              ),
              const _Label('النوع'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in WirdType.values)
                    _Choice(
                      key: ValueKey('type-${t.name}'),
                      label: t.label,
                      note: t.selectable ? null : 'قريباً',
                      selected: _type == t,
                      onTap: t.selectable ? () => _setType(t) : null,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                key: const ValueKey('wird-start-page'),
                controller: _startPage,
                keyboardType: TextInputType.number,
                inputFormatters: [const DigitsOnlyFormatter()],
                decoration: const InputDecoration(
                  labelText: 'صفحة البداية من 1 إلى 604',
                ),
                validator: _validateStartPage,
              ),
              const _Label('الكمية اليومية'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Choice(
                    key: const ValueKey('amount-pages'),
                    label: 'عدد الصفحات يومياً',
                    selected: _amount == _Amount.pagesPerDay,
                    onTap: () => setState(() => _amount = _Amount.pagesPerDay),
                  ),
                  _Choice(
                    key: const ValueKey('amount-date'),
                    label: 'تاريخ الانتهاء',
                    selected: _amount == _Amount.targetDate,
                    onTap: () => setState(() => _amount = _Amount.targetDate),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_amount == _Amount.pagesPerDay)
                TextFormField(
                  key: const ValueKey('wird-pages'),
                  controller: _pages,
                  keyboardType: TextInputType.number,
                  inputFormatters: [const DigitsOnlyFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'عدد الصفحات في اليوم',
                  ),
                  validator: _validatePages,
                )
              else
                OutlinedButton.icon(
                  key: const ValueKey('wird-target-date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _target == null ? 'اختر تاريخ الانتهاء' : _date(_target!),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: look.accent,
                    side: BorderSide(color: look.controlBorder),
                  ),
                ),
              if (_amount == _Amount.targetDate && _targetMissing)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12),
                  child: Text(
                    'اختر تاريخاً',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const _Label('التذكير'),
              SwitchListTile(
                key: const ValueKey('wird-notify'),
                contentPadding: EdgeInsets.zero,
                title: const Text('تذكير يومي'),
                value: _notify,
                onChanged: (v) => setState(() {
                  _notify = v;
                  _notifyTouched = true;
                }),
              ),
              if (_notify)
                ListTile(
                  key: const ValueKey('wird-notify-time'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('وقت التذكير'),
                  trailing: Text(
                    formatMinutes(_minutes),
                    style: TextStyle(fontSize: 16, color: look.accent),
                  ),
                  onTap: _pickTime,
                ),
              const _Label('اللون'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < wirdPalette.length; i++)
                    _ColorDot(
                      key: ValueKey('color-$i'),
                      color: wirdPalette[i],
                      selected: _color == wirdPalette[i],
                      onTap: () => setState(() => _color = wirdPalette[i]),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                key: const ValueKey('wird-save'),
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('حفظ الورد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.look.textSecondary,
      ),
    ),
  );
}

/// A selectable pill. [onTap] null means disabled; [note] is a small line under the label.
class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.note,
  });

  final String label;
  final String? note;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final enabled = onTap != null;
    final fg = selected ? look.onPrimary : look.text;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: selected ? look.primaryFill : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? look.primaryFill : look.controlBorder,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                  if (note != null)
                    Text(note!, style: TextStyle(fontSize: 10, color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    // The swatch is drawn as the wird's marker will be, so on a dark page the colour that is shown is the one the
    // list will show; the colour that is saved stays the palette's own.
    final shown = markerColor(look, Color(color));
    final tick = contrastRatio(Colors.white, shown) >= 3.0
        ? Colors.white
        : Colors.black;
    return Semantics(
      button: true,
      selected: selected,
      label: 'لون الورد',
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: shown,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? look.accent : look.line,
                  width: selected ? 3 : 1,
                ),
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: selected
                    ? Icon(Icons.check, size: 18, color: tick)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
