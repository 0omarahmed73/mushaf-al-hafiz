import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  final now = DateTime(2026, 11, 20, 10, 0);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    await repo.ensureDefaults();
  });
  tearDown(() => db.close());

  test('a fresh database says Thursday and stores nothing for it', () async {
    expect(await repo.kahfDay(), KahfDay.thursday);
    expect(await repo.readSetting('kahfDay'), isNull);
  });

  test('setKahfDay saves Friday and Thursday', () async {
    await repo.setKahfDay(KahfDay.friday);
    expect(await repo.kahfDay(), KahfDay.friday);
    expect(await repo.readSetting('kahfDay'), 'friday');
    await repo.setKahfDay(KahfDay.thursday);
    expect(await repo.kahfDay(), KahfDay.thursday);
    expect(await repo.readSetting('kahfDay'), 'thursday');
  });

  test('a stored text the app does not know reads as Thursday', () async {
    await repo.writeSetting('kahfDay', 'monday');
    expect(await repo.kahfDay(), KahfDay.thursday);
    await repo.writeSetting('kahfDay', '');
    expect(await repo.kahfDay(), KahfDay.thursday);
    await repo.writeSetting('kahfDay', 'Friday');
    expect(await repo.kahfDay(), KahfDay.thursday);
  });

  test('the day and the switch and hour never write each other', () async {
    await repo.setKahf(enabled: false, minutes: 7 * 60 + 30);
    await repo.setKahfDay(KahfDay.friday);
    expect(await repo.kahfEnabled(), isFalse);
    expect(await repo.kahfMinutes(), 7 * 60 + 30);
    await repo.setKahf(enabled: true, minutes: 20 * 60);
    expect(await repo.kahfDay(), KahfDay.friday);
  });

  test('reminderInputs carries the day', () async {
    expect((await repo.reminderInputs(now)).kahfDay, KahfDay.thursday);
    await repo.setKahfDay(KahfDay.friday);
    final inputs = await repo.reminderInputs(now);
    expect(inputs.kahfDay, KahfDay.friday);
    expect(inputs.kahfEnabled, isTrue);
    expect(
      inputs.kahfMinutes,
      10 * 60,
      reason: 'no hour was chosen: Friday\'s default',
    );
  });

  test('ReminderInputs built without a day is Thursday', () {
    const inputs = ReminderInputs(
      wirds: [],
      doneToday: {},
      todayPortions: {},
      kahfEnabled: true,
      kahfMinutes: 21 * 60,
    );
    expect(inputs.kahfDay, KahfDay.thursday);
  });
}
