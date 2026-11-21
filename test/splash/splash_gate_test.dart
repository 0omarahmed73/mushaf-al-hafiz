import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_gate.dart';
import 'package:mushaf/splash/splash_screen.dart';

import 'support/splash_harness.dart';

/// A stand-in for the app: it counts how often its state was created.
class Probe extends StatefulWidget {
  const Probe({super.key});

  @override
  State<Probe> createState() => ProbeState();
}

class ProbeState extends State<Probe> {
  static int created = 0;

  @override
  void initState() {
    super.initState();
    created++;
  }

  @override
  Widget build(BuildContext context) =>
      const Text('الآية', textDirection: TextDirection.rtl);
}

void main() {
  setUp(() => ProbeState.created = 0);

  testWidgets('the app is built from the first frame, under the splash', (
    tester,
  ) async {
    await tester.pumpWidget(const SplashGate(child: Probe()));
    expect(ProbeState.created, 1);
    expect(find.byType(Probe), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('the gate gives its splash a right-to-left direction', (
    tester,
  ) async {
    await tester.pumpWidget(const SplashGate(child: Probe()));
    final context = tester.element(find.byType(SplashScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('after the splash the app is still the same one', (tester) async {
    await startSplash(tester, const SplashGate(child: Probe()));
    final before = tester.state(find.byType(Probe));
    await advance(tester, 1400 + 220);
    await advance(tester, 100);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(Probe), findsOneWidget);
    expect(tester.state(find.byType(Probe)), same(before));
    expect(ProbeState.created, 1);
  });
}
