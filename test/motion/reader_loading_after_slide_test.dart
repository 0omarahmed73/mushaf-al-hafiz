// Feature 010 T013 (FR-005): loading the pages around the shown one does not start in the middle of a slide; it starts when
// the slide has ended, the pages in the direction of the turn first.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

import '../support/motion_harness.dart';
import '../support/motion_probe.dart';

class _Recording extends MushafRepository {
  _Recording(super.bundle);

  /// Which phase of the test asked for which page to be prefetched.
  final List<(String?, int)> prefetches = [];
  String? Function() phase = () => null;

  @override
  Future<void> prefetch(int page) {
    prefetches.add((phase(), page));
    return super.prefetch(page);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'no prefetch starts while the finger is down or the page is sliding; the neighbours are asked for after it, forward first',
    (t) async {
      final repo = _Recording(rootBundle);
      final reader = await pumpMotionReader(
        t,
        startPage: 50,
        withWird: false,
        repository: repo,
      );
      repo.phase = () => reader.probe.phase;
      repo.prefetches.clear();
      await reader.swipeToNext(t, prefix: 'turn-');
      final during = repo.prefetches
          .where(
            (e) =>
                e.$1 != null &&
                (e.$1!.contains('turn-a') ||
                    e.$1!.contains('turn-b') ||
                    e.$1!.contains('turn-c')),
          )
          .toList();
      expect(
        during,
        isEmpty,
        reason: 'nothing is requested before the finger lets go',
      );
      final after = [for (final e in repo.prefetches) e.$2];
      expect(
        after,
        isNotEmpty,
        reason: 'the new page asks for its neighbours once it has settled',
      );
      expect(
        after.first,
        52,
        reason: 'the page in the direction of the turn comes first (page 51 is shown now)',
      );
      expect(after, containsAll([52, 53, 50, 49]));
      motionLog('T013 prefetches after the turn to 51: $after');
    },
  );
}
