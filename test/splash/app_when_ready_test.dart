import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/app_when_ready.dart';
import 'package:mushaf/splash/splash_palette.dart';

void main() {
  testWidgets('a dark box until the app exists, then the app', (tester) async {
    final done = Completer<Widget>();
    await tester.pumpWidget(AppWhenReady(done.future));
    final box = tester.widget<ColoredBox>(find.byType(ColoredBox));
    expect(box.color, SplashColors.background);
    expect(find.text('الصفحة'), findsNothing);

    done.complete(const Text('الصفحة', textDirection: TextDirection.rtl));
    await tester.pump();
    await tester.pump();
    expect(find.text('الصفحة'), findsOneWidget);
    expect(find.byType(ColoredBox), findsNothing);
  });

  testWidgets('a failed start is rethrown, not hidden', (tester) async {
    final done = Completer<Widget>();
    await tester.pumpWidget(AppWhenReady(done.future));
    done.completeError(StateError('the database could not be opened'));
    await tester.pump();
    await tester.pump();
    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect((error! as StateError).message, contains('database'));
  });

  testWidgets('an app that was ready already is shown at the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppWhenReady(
        Future.value(const Text('جاهز', textDirection: TextDirection.rtl)),
      ),
    );
    await tester.pump();
    expect(find.text('جاهز'), findsOneWidget);
  });
}
