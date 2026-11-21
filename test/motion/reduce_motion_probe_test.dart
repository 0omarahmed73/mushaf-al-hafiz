// Feature 010 measurement M5: what the framework does by itself when the phone's «remove animations» setting is on, so the
// plan knows which motion the app must switch off itself (research.md D7). Counts the frames each motion needs to finish.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/motion_probe.dart';

/// Frames of 16 ms until nothing moves any more (at most 60).
Future<int> _framesToSettle(WidgetTester t) async {
  var frames = 0;
  while (t.binding.hasScheduledFrame && frames < 60) {
    await t.pump(const Duration(milliseconds: 16));
    frames++;
  }
  return frames;
}

class _Host extends StatelessWidget {
  const _Host({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    home: const Scaffold(body: Text('home')),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final reduce in [false, true]) {
    final label = reduce ? 'animations removed' : 'animations on';
    testWidgets('M5: frames needed by the framework\'s own motion, $label', (
      t,
    ) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduce);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final key = GlobalKey<NavigatorState>();
      await t.pumpWidget(_Host(navigatorKey: key));
      final context = key.currentContext!;
      expect(
        MediaQuery.disableAnimationsOf(context),
        reduce,
        reason: 'the setting reaches MediaQuery',
      );

      final results = <String, int>{};

      key.currentState!.push(
        PageRouteBuilder<void>(pageBuilder: (_, _, _) => const SizedBox()),
      );
      await t.pump();
      results['route push (PageRouteBuilder default)'] = await _framesToSettle(
        t,
      );
      key.currentState!.pop();
      await t.pump();
      results['route pop'] = await _framesToSettle(t);

      unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
        ),
      );
      await t.pump();
      results['modal bottom sheet open'] = await _framesToSettle(t);
      key.currentState!.pop();
      await t.pump();
      results['modal bottom sheet close'] = await _framesToSettle(t);

      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const Text('dialog'),
        ),
      );
      await t.pump();
      results['dialog open'] = await _framesToSettle(t);
      key.currentState!.pop();
      await t.pump();
      results['dialog close'] = await _framesToSettle(t);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('message'),
          duration: Duration(seconds: 30),
        ),
      );
      await t.pump();
      results['snack bar in'] = await _framesToSettle(t);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await t.pump();
      results['snack bar out'] = await _framesToSettle(t);

      final shown = ValueNotifier<bool>(false);
      addTearDown(shown.dispose);
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (_, on, _) => AnimatedOpacity(
              opacity: on ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );
      shown.value = true;
      await t.pump();
      results['AnimatedOpacity 200 ms (implicit animation of the app)'] =
          await _framesToSettle(t);

      // The reader's edge turn: PageController.animateToPage (a scroll activity, whose controller preserves its duration).
      final controller = PageController();
      addTearDown(controller.dispose);
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PageView(
            controller: controller,
            children: const [SizedBox(), SizedBox()],
          ),
        ),
      );
      unawaited(
        controller.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
      await t.pump();
      results['PageController.animateToPage 300 ms (the edge turn)'] =
          await _framesToSettle(t);

      motionLog(
        'M5 $label: ${results.entries.map((e) => '${e.key}=${e.value} frames').join('; ')}',
      );
    });
  }
}
