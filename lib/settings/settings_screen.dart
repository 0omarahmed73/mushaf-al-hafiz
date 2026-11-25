import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../backup/backup.dart';
import '../backup/backup_service.dart';
import '../look/look_settings.dart';
import '../mushaf/ayah_bookmark_strings.dart';
import '../reminders/kahf_day.dart';
import '../reminders/kahf_strings.dart';
import '../reminders/reminder_scheduler.dart';
import '../theme.dart';
import '../wirds/portion.dart';
import '../wirds/wird_repository.dart';
import 'about_screen.dart';
import 'ayah_tint_settings.dart';
import '../large_ayah/large_ayah_tile.dart';
import 'look_tile.dart';
import 'text_size_tile.dart';

/// Opened by «☰»: the al-Kahf reminder (on/off, day and time), the notification permission (a line and a
/// button when the phone does not allow notifications), backup export and import, and About
/// (spec FR-038). Pops `true` after a backup was restored so the reader can reload.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  late final WirdRepository _repo = context.read<WirdRepository>();
  late final Reminders? _reminders = context.read<Reminders?>();
  late final Backup? _backup = context.read<Backup?>();
  bool _loaded = false;
  bool _kahfEnabled = true;
  int _kahfMinutes = WirdRepository.defaultKahfMinutes;
  bool _kahfMinutesChosen = false;
  KahfDay _kahfDay = KahfDay.thursday;
  bool? _allowed;
  bool _askedHere = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the phone's own settings: look at the permission again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAllowed();
  }

  Future<void> _load() async {
    final enabled = await _repo.kahfEnabled();
    final minutes = await _repo.kahfMinutes();
    final chosen = await _repo.kahfMinutesChosen();
    final day = await _repo.kahfDay();
    final allowed = await _reminders?.service.notificationsAllowed();
    if (!mounted) return;
    setState(() {
      _kahfEnabled = enabled;
      _kahfMinutes = minutes;
      _kahfMinutesChosen = chosen;
      _kahfDay = day;
      _allowed = allowed;
      _loaded = true;
    });
  }

  Future<void> _checkAllowed() async {
    final allowed = await _reminders?.service.notificationsAllowed();
    if (!mounted) return;
    setState(() => _allowed = allowed);
    if (allowed ?? false) _reminders?.scheduler.refresh(force: true);
  }

  /// The switch alone: it stores no hour, so an hour nobody chose still follows the day.
  Future<void> _saveKahfEnabled(bool enabled) async {
    setState(() => _kahfEnabled = enabled);
    await _repo.setKahfEnabled(enabled);
  }

  /// The picker: the hour is now the user's and wins over the default of either day.
  Future<void> _saveKahfMinutes(int minutes) async {
    setState(() {
      _kahfMinutes = minutes;
      _kahfMinutesChosen = true;
    });
    await _repo.setKahfMinutes(minutes);
  }

  /// A tap on the other day's card: shown at once, then saved; the scheduler follows the settings change. An hour
  /// nobody chose becomes the new day's default (21:00 Thursday, 10:00 Friday); a chosen one stays.
  Future<void> _saveKahfDay(KahfDay day) async {
    if (day == _kahfDay) return;
    setState(() {
      _kahfDay = day;
      if (!_kahfMinutesChosen) _kahfMinutes = day.defaultMinutes;
    });
    await _repo.setKahfDay(day);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _kahfMinutes ~/ 60,
        minute: _kahfMinutes % 60,
      ),
    );
    if (picked != null) {
      await _saveKahfMinutes(picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _requestPermission() async {
    final allowed = await _reminders?.service.requestPermission();
    if (!mounted) return;
    setState(() {
      _allowed = allowed;
      _askedHere = true;
    });
    if (allowed ?? false) _reminders?.scheduler.refresh(force: true);
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    final backup = _backup;
    if (backup == null) return;
    try {
      final now = DateTime.now();
      final json = await backup.service.exportJson(now: now);
      await backup.files.share(fileName: backupFileName(now), json: json);
    } catch (_) {
      if (mounted) _say('تعذّر تصدير النسخة الاحتياطية.');
    }
  }

  static String _refusal(BackupProblem p) => switch (p) {
    BackupProblem.notABackup =>
      'هذا الملف ليس نسخة احتياطية من «مصحف الحافظ». لم يتغيّر شيء.',
    BackupProblem.newerVersion =>
      'هذه النسخة الاحتياطية أحدث من هذا التطبيق. لم يتغيّر شيء.',
    BackupProblem.invalid =>
      'ملف النسخة الاحتياطية تالف أو غير صالح. لم يتغيّر شيء.',
  };

  Future<void> _import() async {
    final backup = _backup;
    if (backup == null) return;
    final lookSetting = context.read<AppLookSettings?>();
    final String? text;
    try {
      text = await backup.files.pick();
    } on FormatException {
      if (mounted) _say(_refusal(BackupProblem.invalid));
      return;
    } catch (_) {
      if (mounted) _say('تعذّرت قراءة الملف.');
      return;
    }
    if (text == null) return; // the user cancelled the picker
    try {
      backup.service.check(
        text,
      ); // refuse a bad file before asking to replace anything
    } on BackupFormatException catch (e) {
      if (mounted) _say(_refusal(e.problem));
      return;
    }
    if (!mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('سيُستبدل كل ما في التطبيق. متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            key: const ValueKey('import-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await backup.service.importJson(text);
    } on BackupFormatException catch (e) {
      if (mounted) _say(_refusal(e.problem));
      return;
    } catch (_) {
      if (mounted) _say('تعذّر الاسترجاع. لم يتغيّر شيء.');
      return;
    }
    _reminders?.scheduler.refresh(force: true);
    // The backup replaced every setting, the look included (Emerald & Gold when it has none): show it at once.
    await lookSetting?.reload();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    // The switch of the tint (feature 013, FR-024); an app with no such setting shows no switch.
    final ayahTint = context.watch<AyahTintSettings?>();
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        top: false,
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
                children: [
                  // Feature 015: the large-ayah view, first so an elderly reader finds it at once.
                  const LargeAyahTile(),
                  const LookTile(),
                  if (_allowed == false) ...[
                    _PermissionCard(
                      askedHere: _askedHere,
                      onRequest: _requestPermission,
                    ),
                    const SizedBox(height: 18),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    child: Text(
                      'التذكيرات',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: look.textSecondary,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    key: const ValueKey('kahf-switch'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _kahfDay == KahfDay.friday
                          ? kKahfSwitchTitleFriday
                          : kKahfSwitchTitleThursday,
                    ),
                    subtitle: Text(
                      _kahfDay == KahfDay.friday
                          ? kKahfSwitchSubtitleFriday
                          : kKahfSwitchSubtitleThursday,
                      style: TextStyle(color: look.textSecondary),
                    ),
                    value: _kahfEnabled,
                    onChanged: _saveKahfEnabled,
                  ),
                  if (_kahfEnabled)
                    _KahfDayChoice(day: _kahfDay, onChanged: _saveKahfDay),
                  if (_kahfEnabled)
                    ListTile(
                      key: const ValueKey('kahf-time'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('وقت التذكير'),
                      trailing: Text(
                        formatMinutes(_kahfMinutes),
                        style: TextStyle(fontSize: 16, color: look.accent),
                      ),
                      onTap: _pickTime,
                    ),
                  const TextSizeTile(),
                  if (ayahTint != null)
                    SwitchListTile(
                      key: const ValueKey('ayah-tint-switch'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(kAyahTintTitle),
                      subtitle: Text(
                        kAyahTintSubtitle,
                        style: TextStyle(color: look.textSecondary),
                      ),
                      value: ayahTint.enabled,
                      // Saved at once; the reader behind follows it live.
                      onChanged: ayahTint.set,
                    ),
                  if (_backup != null) ...[
                    const _SectionLabel('النسخ الاحتياطي'),
                    ListTile(
                      key: const ValueKey('backup-export'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.upload_file_outlined),
                      title: const Text('تصدير نسخة احتياطية'),
                      subtitle: Text(
                        'ملف واحد فيه الأوراد والعلامات والإعدادات',
                        style: TextStyle(color: look.textSecondary),
                      ),
                      onTap: _export,
                    ),
                    ListTile(
                      key: const ValueKey('backup-import'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('استيراد نسخة احتياطية'),
                      subtitle: Text(
                        'يستبدل كل ما في التطبيق بما في الملف',
                        style: TextStyle(color: look.textSecondary),
                      ),
                      onTap: _import,
                    ),
                  ],
                  const _SectionLabel('التطبيق'),
                  ListTile(
                    key: const ValueKey('open-about'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: const Text('عن التطبيق'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutScreen(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The two days of the al-Kahf reminder as two cards (stacked on a narrow window or with a large system font), the
/// chosen one marked by a thicker outline and a check so that colour is not the only sign. It has no visible heading:
/// the screen is tight (the screen's own tests need «التطبيق» still on a 412 x 915 window), so «يوم التذكير» names the
/// group for a screen reader only. The words are proposals in `kahf_strings.dart` (feature 007).
class _KahfDayChoice extends StatelessWidget {
  const _KahfDayChoice({required this.day, required this.onChanged});

  final KahfDay day;
  final ValueChanged<KahfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _DayCard(
        key: const ValueKey('kahf-day-thursday'),
        label: kKahfDayThursdayLabel,
        name: kKahfDayThursdayName,
        selected: day == KahfDay.thursday,
        onTap: () => onChanged(KahfDay.thursday),
      ),
      _DayCard(
        key: const ValueKey('kahf-day-friday'),
        label: kKahfDayFridayLabel,
        name: kKahfDayFridayLabel,
        selected: day == KahfDay.friday,
        onTap: () => onChanged(KahfDay.friday),
      ),
    ];
    return Semantics(
      key: const ValueKey('kahf-day'),
      container: true,
      label: kKahfDayHeading,
      child: LayoutBuilder(
        builder: (context, box) {
          // Under 340 dp wide, or with a large system font, two cards do not fit side by side.
          final stacked =
              box.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(15) > 17;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cards[0], const SizedBox(height: 8), cards[1]],
            );
          }
          // IntrinsicHeight keeps the two as tall as the taller one, also inside a scroll view.
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 10),
                Expanded(child: cards[1]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    super.key,
    required this.label,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  /// What is drawn, and [name], what a screen reader says (it may say more).
  final String label;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final radius = BorderRadius.circular(look.cardRadius);
    return Semantics(
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
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 4),
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.askedHere, required this.onRequest});

  final bool askedHere;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return DecoratedBox(
      key: const ValueKey('permission-card'),
      decoration: BoxDecoration(
        border: Border.all(color: look.controlBorder, width: 1.5),
        borderRadius: BorderRadius.circular(look.rowRadius(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإشعارات غير مسموحة لهذا التطبيق، فلن تصلك تذكيرات الأوراد ولا تذكير سورة الكهف.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            if (askedHere)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'إن لم يظهر طلب الإذن، فعّل الإشعارات للتطبيق من إعدادات الهاتف ثم عد إليه.',
                  style: TextStyle(
                    fontSize: 13,
                    color: look.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('allow-notifications'),
              onPressed: onRequest,
              child: const Text('السماح بالإشعارات'),
            ),
          ],
        ),
      ),
    );
  }
}
