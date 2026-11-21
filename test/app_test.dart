import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  testWidgets('the app is Arabic and right-to-left', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(MushafApp(
      wirdRepository: WirdRepository(db),
      mushafRepository: MushafRepository(rootBundle),
      home: const Scaffold(body: Center(child: Text('مصحف الحافظ'))),
    ));
    await tester.pump();
    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Localizations.localeOf(context).languageCode, 'ar');
    expect(find.text('مصحف الحافظ'), findsWidgets);
  });
}
