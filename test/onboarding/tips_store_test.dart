// The stored fact of the first-run tips (feature 008, data-model.md "The flag: tipsSeen"): one row of the settings
// table, read once and written once.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/onboarding/tips_store.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
  });
  tearDown(() => db.close());

  test('the key is the literal tipsSeen', () {
    expect(kTipsSeenKey, 'tipsSeen');
  });

  test('only exactly "true" means seen', () {
    expect(TipsStore.isSeen('true'), isTrue);
    for (final other in [
      null,
      '',
      'false',
      'True',
      'TRUE',
      '1',
      ' true',
      'yes',
    ]) {
      expect(TipsStore.isSeen(other), isFalse, reason: '"$other"');
    }
  });

  test('an empty database has not seen the tips', () async {
    expect(await TipsStore(repo).seen(), isFalse);
  });

  test('markSeen stores "true" and seen reads it', () async {
    final store = TipsStore(repo);
    await store.markSeen();
    expect(await store.seen(), isTrue);
    expect(await repo.readSetting(kTipsSeenKey), 'true');
  });

  test('marking twice changes nothing', () async {
    final store = TipsStore(repo);
    await store.markSeen();
    await store.markSeen();
    expect(await store.seen(), isTrue);
    expect(
      (await db.select(db.settings).get()).where((s) => s.key == 'tipsSeen'),
      hasLength(1),
    );
  });

  test('it writes no other setting', () async {
    await TipsStore(repo).markSeen();
    final keys = (await db.select(db.settings).get())
        .map((s) => s.key)
        .toList();
    expect(keys, ['tipsSeen']);
  });

  test('a damaged value counts as not seen', () async {
    await repo.writeSetting(kTipsSeenKey, 'maybe');
    expect(await TipsStore(repo).seen(), isFalse);
  });

  group('maybeOf', () {
    testWidgets('is null without a repository in the tree', (t) async {
      TipsStore? found = TipsStore(repo);
      await t.pumpWidget(
        Builder(
          builder: (context) {
            found = TipsStore.maybeOf(context);
            return const SizedBox();
          },
        ),
      );
      expect(found, isNull);
    });

    testWidgets('is a store of the app repository when there is one', (
      t,
    ) async {
      TipsStore? found;
      await t.pumpWidget(
        Provider<WirdRepository>.value(
          value: repo,
          child: Builder(
            builder: (context) {
              found = TipsStore.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found, isNotNull);
      await t.runAsync(() => found!.markSeen());
      expect(await t.runAsync(() => repo.readSetting(kTipsSeenKey)), 'true');
    });
  });
}
