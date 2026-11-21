// Feature 011, T010: SearchSession (the screen's logic: the view states, stale answers, the announcement gate) with no
// widgets, over a fake service whose scan completes on demand and the fake clock of testWidgets (spec FR-009, FR-014,
// FR-023, FR-027; research D5, D13; contracts/ui.md "States").
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_target.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_session.dart';
import 'package:mushaf/search/search_strings.dart';
import 'package:mushaf/search/surah_search.dart';

import '../support/search_harness.dart';

/// One scan the session asked the fake service for.
class Ask {
  Ask(this.query, this.isCurrent);
  final String query;
  final bool Function() isCurrent;
  final Completer<AyahSearchResult?> completer = Completer();
}

/// A service whose phase the test sets and whose scans complete when the test says so.
class FakeService extends ChangeNotifier implements SearchService {
  FakeService([IndexPhase phase = IndexPhase.ready]) : _phase = phase;

  IndexPhase _phase;
  Object? _failure;
  final List<Ask> asks = [];
  int retries = 0;

  /// What `retry()` does: by default the service goes to `preparing`, as the real one.
  void Function() onRetry = () {};

  @override
  IndexPhase get phase => _phase;

  @override
  Object? get failure => _failure;

  void setPhase(IndexPhase phase, {Object? failure}) {
    _phase = phase;
    _failure = failure;
    notifyListeners();
  }

  @override
  Future<void> prepare() async {}

  @override
  Future<void> retry() async {
    retries++;
    onRetry();
  }

  @override
  Future<AyahSearchResult?> searchAyat(
    String foldedQuery, {
    required bool Function() isCurrent,
  }) {
    final ask = Ask(foldedQuery, isCurrent);
    asks.add(ask);
    return ask.completer.future;
  }
}

AyahSearchResult resultOf(int total, {int rows = 1}) => AyahSearchResult(
  total: total,
  hits: [
    for (var i = 0; i < rows && i < total; i++)
      AyahHit(
        ref: AyahRef(1, i + 1),
        page: 1,
        words: const ['قُلۡ'],
        matched: const [true],
      ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<SurahInfo> surahs;
  setUpAll(() async {
    surahs = (await realMeta()).surahs;
  });

  final announced = <String>[];

  ({FakeService service, SearchSession session}) make(
    WidgetTester t, {
    IndexPhase phase = IndexPhase.ready,
  }) {
    announced.clear();
    final service = FakeService(phase);
    final session = SearchSession(
      service: service,
      surahs: surahs,
      onAnnounce: announced.add,
    );
    addTearDown(() {
      session.dispose();
      service.dispose();
    });
    return (service: service, session: session);
  }

  List<int> numbers(SearchView v) => [for (final s in v.surahs) s.number];

  group('the table of contracts/ui.md "States"', () {
    testWidgets('the start: nothing typed, the hint line', (t) async {
      final m = make(t);
      final v = m.session.view;
      expect(v.nothingTyped, isTrue);
      expect(v.letters, 0);
      expect(v.surahs, isEmpty);
      expect(v.ayah, isA<AyahHint>());
      expect(v.none, isFalse);
      expect(m.session.typed, '');
    });

    testWidgets(
      'letters 0: empty, spaces, digits, Latin, brackets, only tashkeel, only tatweel are nothing typed',
      (t) async {
        final m = make(t);
        for (final typed in [
          '',
          '   ',
          '123',
          '٢٥٥',
          'abc',
          '﴿ ﴾',
          'َُّ',
          'ـــ',
          '2:255',
        ]) {
          m.session.setQuery(
            'ق',
          ); // leave nothing-typed first so a repeated value is not ignored
          m.session.setQuery(typed);
          final v = m.session.view;
          expect(v.letters, 0, reason: '"$typed"');
          expect(v.nothingTyped, isTrue, reason: '"$typed"');
          expect(v.surahs, isEmpty, reason: '"$typed"');
          expect(v.ayah, isA<AyahHint>(), reason: '"$typed"');
          expect(v.none, isFalse, reason: '"$typed"');
        }
        expect(m.service.asks, isEmpty);
      },
    );

    testWidgets(
      'letters 1: the surah group answers, the ayah group asks for a second letter, nothing is scanned',
      (t) async {
        for (final phase in IndexPhase.values) {
          final m = make(t, phase: phase);
          m.session.setQuery('ق');
          final v = m.session.view;
          expect(v.letters, 1);
          expect(v.surahs.first.number, 50);
          expect(v.ayah, isA<AyahNeedsTwo>(), reason: '$phase');
          expect(v.none, isFalse);
          expect(m.service.asks, isEmpty, reason: '$phase');
        }
      },
    );

    testWidgets(
      'letters 1 with no surah that matches: still the need-two line, not «none»',
      (t) async {
        final m = make(t);
        final letter = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي'
            .split('')
            .firstWhere(
              (c) => searchSurahs(surahs, c).isEmpty,
              orElse: () => '',
            );
        expect(letter, isNotEmpty, reason: 'a letter that is in no surah name');
        m.session.setQuery(letter);
        expect(m.session.view.letters, 1);
        expect(m.session.view.surahs, isEmpty);
        expect(m.session.view.ayah, isA<AyahNeedsTwo>());
        expect(m.session.view.none, isFalse);
      },
    );

    testWidgets(
      '2 or more letters with the service notStarted or preparing: surah rows at once and the preparing state',
      (t) async {
        for (final phase in [IndexPhase.notStarted, IndexPhase.preparing]) {
          final m = make(t, phase: phase);
          m.session.setQuery('كهف');
          final v = m.session.view;
          expect(numbers(v), [18]);
          expect(v.ayah, isA<AyahPreparing>(), reason: '$phase');
          expect(v.none, isFalse);
          expect(m.service.asks, isEmpty);
        }
      },
    );

    testWidgets(
      '2 or more letters with nothing in the surah group and the service preparing: preparing, not none',
      (t) async {
        final m = make(t, phase: IndexPhase.preparing);
        m.session.setQuery('ذو القرنين');
        expect(m.session.view.surahs, isEmpty);
        expect(m.session.view.ayah, isA<AyahPreparing>());
        expect(m.session.view.none, isFalse);
      },
    );

    testWidgets(
      '2 or more letters with the service failed: surah rows and the failure with its error',
      (t) async {
        final m = make(t, phase: IndexPhase.failed);
        final error = StateError('boom');
        m.service.setPhase(IndexPhase.failed, failure: error);
        m.session.setQuery('كهف');
        final v = m.session.view;
        expect(numbers(v), [18]);
        expect(v.ayah, isA<AyahFailed>());
        expect((v.ayah as AyahFailed).error, same(error));
        expect(v.none, isFalse);
        expect(m.service.asks, isEmpty);
      },
    );

    testWidgets(
      'ready with ayat: the heading total and the hits of the answer',
      (t) async {
        final m = make(t);
        m.session.setQuery('رحم');
        expect(m.service.asks, hasLength(1));
        expect(m.service.asks.single.query, ArabicFold.query('رحم'));
        final result = resultOf(201, rows: 100);
        m.service.asks.single.completer.complete(result);
        await t.pump();
        final v = m.session.view;
        expect(v.ayah, isA<AyahResults>());
        expect((v.ayah as AyahResults).result, same(result));
        expect((v.ayah as AyahResults).result.total, 201);
        expect((v.ayah as AyahResults).result.tooMany, isTrue);
        expect(v.none, isFalse);
      },
    );

    testWidgets(
      'ready with no ayah but a surah match: only the surah group, not «none»',
      (t) async {
        final m = make(t);
        m.session.setQuery('كهف');
        m.service.asks.single.completer.complete(resultOf(0));
        await t.pump();
        final v = m.session.view;
        expect(numbers(v), [18]);
        expect((v.ayah as AyahResults).result.total, 0);
        expect(v.none, isFalse);
      },
    );

    testWidgets('ready with nothing in either group: view.none', (t) async {
      final m = make(t);
      m.session.setQuery('ذو القرنين');
      expect(m.session.view.none, isFalse, reason: 'the scan is still running');
      m.service.asks.single.completer.complete(resultOf(0));
      await t.pump();
      final v = m.session.view;
      expect(v.surahs, isEmpty);
      expect(v.letters, greaterThanOrEqualTo(2));
      expect(v.none, isTrue);
    });

    testWidgets(
      'the surah group is answered in the same call as setQuery, with the scan still pending',
      (t) async {
        final m = make(t);
        var notified = 0;
        m.session.addListener(() => notified++);
        m.session.setQuery('الحج');
        expect(numbers(m.session.view), [22, 15, 49]);
        expect(notified, greaterThan(0));
        expect(m.session.view.ayah, isA<AyahSearching>());
        expect(m.service.asks, hasLength(1));
      },
    );

    testWidgets(
      'while a newer scan runs the older results stay (no flicker) and are replaced by the answer',
      (t) async {
        final m = make(t);
        m.session.setQuery('رحم');
        final first = resultOf(201);
        m.service.asks[0].completer.complete(first);
        await t.pump();
        m.session.setQuery('رحمن');
        expect((m.session.view.ayah as AyahResults).result, same(first));
        final second = resultOf(48);
        m.service.asks[1].completer.complete(second);
        await t.pump();
        expect((m.session.view.ayah as AyahResults).result, same(second));
      },
    );
  });

  group('stale answers (FR-023)', () {
    testWidgets(
      'query A then B: B answers first and A answers late: the view shows B and A never replaces it',
      (t) async {
        final m = make(t);
        m.session.setQuery('الله');
        m.session.setQuery('الرحمن');
        expect(m.service.asks, hasLength(2));
        final a = m.service.asks[0], b = m.service.asks[1];
        expect(a.isCurrent(), isFalse);
        expect(b.isCurrent(), isTrue);
        final answerB = resultOf(48);
        b.completer.complete(answerB);
        await t.pump();
        expect((m.session.view.ayah as AyahResults).result, same(answerB));
        var notified = 0;
        m.session.addListener(() => notified++);
        a.completer.complete(resultOf(1746));
        await t.pump();
        expect((m.session.view.ayah as AyahResults).result, same(answerB));
        expect(notified, 0, reason: 'a dropped answer changes nothing');
      },
    );

    testWidgets(
      'a scan whose isCurrent turned false returns null and changes nothing',
      (t) async {
        final m = make(t);
        m.session.setQuery('الله');
        final a = m.service.asks.single;
        m.session.setQuery('الرحمن');
        var notified = 0;
        m.session.addListener(() => notified++);
        a.completer.complete(null);
        await t.pump();
        expect(notified, 0);
        expect(m.session.view.ayah, isA<AyahSearching>());
      },
    );

    testWidgets(
      'typing back to one letter or nothing drops the answer that arrives after',
      (t) async {
        final m = make(t);
        m.session.setQuery('الله');
        final a = m.service.asks.single;
        m.session.setQuery('ا');
        expect(a.isCurrent(), isFalse);
        a.completer.complete(resultOf(1746));
        await t.pump();
        expect(m.session.view.ayah, isA<AyahNeedsTwo>());
        m.session.setQuery('');
        expect(m.session.view.ayah, isA<AyahHint>());
      },
    );

    testWidgets(
      'four letters answered in the order 3, 1, 4, 2: the view ends on the answer of the fourth',
      (t) async {
        final m = make(t);
        for (final typed in ['ر', 'رح', 'رحم', 'رحمن']) {
          m.session.setQuery(typed);
        }
        // one letter is never scanned: three scans for رح, رحم, رحمن
        expect(m.service.asks, hasLength(3));
        final answers = [for (var i = 0; i < 3; i++) resultOf(10 + i)];
        m.service.asks[1].completer.complete(answers[1]);
        await t.pump();
        expect(m.session.view.ayah, isA<AyahSearching>());
        m.service.asks[2].completer.complete(answers[2]);
        await t.pump();
        expect((m.session.view.ayah as AyahResults).result, same(answers[2]));
        m.service.asks[0].completer.complete(answers[0]);
        await t.pump();
        expect((m.session.view.ayah as AyahResults).result, same(answers[2]));
      },
    );
  });

  group('the service', () {
    testWidgets(
      'when it becomes ready the session runs the query that is in the field now',
      (t) async {
        final m = make(t, phase: IndexPhase.preparing);
        m.session.setQuery('رحم');
        expect(m.session.view.ayah, isA<AyahPreparing>());
        m.session.setQuery('رحمن'); // the field changed while it was preparing
        expect(m.service.asks, isEmpty);
        m.service.setPhase(IndexPhase.ready);
        expect(m.service.asks, hasLength(1));
        expect(m.service.asks.single.query, ArabicFold.query('رحمن'));
        final answer = resultOf(48);
        m.service.asks.single.completer.complete(answer);
        await t.pump();
        expect((m.session.view.ayah as AyahResults).result, same(answer));
      },
    );

    testWidgets(
      'notStarted to preparing to ready with nothing typed asks for nothing',
      (t) async {
        final m = make(t, phase: IndexPhase.notStarted);
        m.service.setPhase(IndexPhase.preparing);
        m.service.setPhase(IndexPhase.ready);
        expect(m.service.asks, isEmpty);
        expect(m.session.view.ayah, isA<AyahHint>());
      },
    );

    testWidgets(
      'a failure after the query was typed shows the failure, and the next ready runs the query',
      (t) async {
        final m = make(t, phase: IndexPhase.preparing);
        m.session.setQuery('كهف');
        final error = StateError('x');
        m.service.setPhase(IndexPhase.failed, failure: error);
        expect((m.session.view.ayah as AyahFailed).error, same(error));
        m.service.setPhase(IndexPhase.preparing);
        expect(m.session.view.ayah, isA<AyahPreparing>());
        m.service.setPhase(IndexPhase.ready);
        expect(m.service.asks, hasLength(1));
      },
    );

    testWidgets('retry() runs service.retry() and then the current query', (
      t,
    ) async {
      final m = make(t, phase: IndexPhase.failed);
      m.service.setPhase(IndexPhase.failed, failure: StateError('x'));
      m.session.setQuery('كهف');
      expect(m.session.view.ayah, isA<AyahFailed>());
      m.service.onRetry = () => m.service.setPhase(IndexPhase.preparing);
      await m.session.retry();
      expect(m.service.retries, 1);
      expect(m.session.view.ayah, isA<AyahPreparing>());
      m.service.setPhase(IndexPhase.ready);
      expect(m.service.asks, hasLength(1));
      expect(m.service.asks.single.query, ArabicFold.query('كهف'));
    });

    testWidgets(
      'retry() with a service that is ready when it returns (no notification) runs the current query once',
      (t) async {
        final m = make(t, phase: IndexPhase.failed);
        m.session.setQuery('كهف');
        m.service._phase = IndexPhase.ready; // silently, as a service whose retry finished without a notification
        await m.session.retry();
        expect(m.service.asks, hasLength(1));
      },
    );

    testWidgets('retry() that fails again shows the failure line again', (
      t,
    ) async {
      final m = make(t, phase: IndexPhase.failed);
      m.service.setPhase(IndexPhase.failed, failure: StateError('first'));
      m.session.setQuery('كهف');
      m.service.onRetry = () {
        m.service.setPhase(IndexPhase.preparing);
        m.service.setPhase(IndexPhase.failed, failure: StateError('second'));
      };
      await m.session.retry();
      expect(
        ((m.session.view.ayah as AyahFailed).error as StateError).message,
        'second',
      );
    });
  });

  group('typed is never altered', () {
    testWidgets(
      'the session keeps exactly what was typed: spaces, tashkeel, tatweel and 1,500 characters',
      (t) async {
        final m = make(t);
        final long = ('قُلۡ هُوَ ٱللَّهُ أَحَدٌ ' * 100).substring(0, 1500);
        for (final typed in ['  قُلۡ  ', 'ابراهيـم', ' ', 'A b', long]) {
          m.session.setQuery(typed);
          expect(m.session.typed, typed);
        }
        expect(m.session.typed.length, 1500);
        // the query handed to the service is the fold of exactly that text
        expect(m.service.asks.last.query, ArabicFold.query(long));
      },
    );

    testWidgets('the same text again does not start another scan', (t) async {
      final m = make(t);
      m.session.setQuery('رحم');
      m.session.setQuery('رحم');
      expect(m.service.asks, hasLength(1));
    });
  });

  group('dispose', () {
    testWidgets(
      'an answer or a phase change after dispose changes nothing and throws nothing',
      (t) async {
        final service = FakeService();
        final session = SearchSession(
          service: service,
          surahs: surahs,
          onAnnounce: announced.add,
        );
        announced.clear();
        session.setQuery('رحم');
        final ask = service.asks.single;
        session.dispose();
        expect(ask.isCurrent(), isFalse);
        ask.completer.complete(resultOf(5));
        await t.pump(const Duration(seconds: 2));
        service.setPhase(IndexPhase.preparing);
        service.setPhase(IndexPhase.ready);
        await t.pump(const Duration(seconds: 2));
        expect(announced, isEmpty);
        expect(service.asks, hasLength(1));
        service.dispose();
      },
    );
  });

  group('AnnouncementGate', () {
    const quiet = Duration(milliseconds: 700);

    testWidgets(
      'sends once, 700 ms after the last touch, with the text of the last touch',
      (t) async {
        final sent = <String>[];
        final gate = AnnouncementGate(quiet: quiet, send: sent.add);
        addTearDown(gate.dispose);
        gate.touch('a');
        await t.pump(const Duration(milliseconds: 699));
        expect(sent, isEmpty);
        await t.pump(const Duration(milliseconds: 1));
        expect(sent, ['a']);
        await t.pump(const Duration(seconds: 5));
        expect(sent, ['a']);
      },
    );

    testWidgets(
      'a new touch restarts the wait and only the last text is sent',
      (t) async {
        final sent = <String>[];
        final gate = AnnouncementGate(quiet: quiet, send: sent.add);
        addTearDown(gate.dispose);
        gate.touch('a');
        await t.pump(const Duration(milliseconds: 400));
        gate.touch('b');
        await t.pump(const Duration(milliseconds: 400));
        gate.touch('c');
        await t.pump(const Duration(milliseconds: 699));
        expect(sent, isEmpty);
        await t.pump(const Duration(milliseconds: 1));
        expect(sent, ['c']);
      },
    );

    testWidgets(
      'sends nothing when the text equals the last one sent; sends it again after another text',
      (t) async {
        final sent = <String>[];
        final gate = AnnouncementGate(quiet: quiet, send: sent.add);
        addTearDown(gate.dispose);
        gate.touch('a');
        await t.pump(quiet);
        gate.touch('a');
        await t.pump(quiet);
        expect(sent, ['a']);
        gate.touch('b');
        await t.pump(quiet);
        gate.touch('a');
        await t.pump(quiet);
        expect(sent, ['a', 'b', 'a']);
      },
    );

    testWidgets(
      'a touch that goes back to the last sent text before the wait ends sends nothing',
      (t) async {
        final sent = <String>[];
        final gate = AnnouncementGate(quiet: quiet, send: sent.add);
        addTearDown(gate.dispose);
        gate.touch('a');
        await t.pump(quiet);
        gate.touch('b');
        await t.pump(const Duration(milliseconds: 300));
        gate.touch('a');
        await t.pump(quiet);
        expect(sent, ['a']);
      },
    );

    testWidgets(
      'an empty text is never sent and forgets the last sent text (a new result of the same words is announced again)',
      (t) async {
        final sent = <String>[];
        final gate = AnnouncementGate(quiet: quiet, send: sent.add);
        addTearDown(gate.dispose);
        gate.touch('a');
        await t.pump(quiet);
        gate.touch('');
        await t.pump(quiet);
        expect(sent, ['a']);
        gate.touch('a');
        await t.pump(quiet);
        expect(sent, ['a', 'a']);
      },
    );

    testWidgets(
      'dispose cancels what is waiting; a touch after dispose does nothing',
      (t) async {
        final sent = <String>[];
        final gate = AnnouncementGate(quiet: quiet, send: sent.add);
        gate.touch('a');
        await t.pump(const Duration(milliseconds: 300));
        gate.dispose();
        await t.pump(const Duration(seconds: 5));
        expect(sent, isEmpty);
        gate.touch('b');
        await t.pump(const Duration(seconds: 5));
        expect(sent, isEmpty);
        gate.dispose(); // twice is fine
      },
    );
  });

  group('the announcement of the session', () {
    testWidgets(
      'typing letter by letter sends one announcement 700 ms after the last change: the two headings\' labels',
      (t) async {
        final m = make(t);
        for (final typed in ['ك', 'كه', 'كهف']) {
          m.session.setQuery(typed);
          await t.pump(const Duration(milliseconds: 100));
        }
        // the scan of كهف (the only one asked, one letter is not scanned) answers
        m.service.asks.last.completer.complete(resultOf(17));
        await t.pump(const Duration(milliseconds: 100));
        expect(announced, isEmpty, reason: 'still inside the quiet time');
        await t.pump(const Duration(milliseconds: 700));
        expect(announced, [announcementOf(m.session.view)]);
        expect(announced.single, contains(kSurahHeadingSemantics(1)));
        expect(announced.single, contains(kAyahHeadingSemantics(17)));
        await t.pump(const Duration(seconds: 5));
        expect(announced, hasLength(1));
      },
    );

    testWidgets('nothing in either group: «لا توجد نتائج»', (t) async {
      final m = make(t);
      m.session.setQuery('ذو القرنين');
      m.service.asks.single.completer.complete(resultOf(0));
      await t.pump(const Duration(seconds: 1));
      expect(announced, [kSearchNone]);
    });

    testWidgets('only the surah group has rows: only its label', (t) async {
      final m = make(t);
      m.session.setQuery('كهف');
      m.service.asks.single.completer.complete(resultOf(0));
      await t.pump(const Duration(seconds: 1));
      expect(announced, [kSurahHeadingSemantics(1)]);
    });

    testWidgets('only the ayah group has rows: only its label', (t) async {
      final m = make(t);
      m.session.setQuery('ذو القرنين');
      m.service.asks.single.completer.complete(resultOf(3));
      await t.pump(const Duration(seconds: 1));
      expect(announced, [kAyahHeadingSemantics(3)]);
    });

    testWidgets(
      'nothing typed, the need-two line, preparing and failed announce nothing',
      (t) async {
        final m = make(t, phase: IndexPhase.preparing);
        m.session.setQuery('ذو القرنين');
        await t.pump(const Duration(seconds: 2));
        m.session.setQuery('ظ');
        await t.pump(const Duration(seconds: 2));
        m.session.setQuery('');
        await t.pump(const Duration(seconds: 2));
        expect(announced, isEmpty);
      },
    );

    testWidgets('a change that leaves the same text is not announced again', (
      t,
    ) async {
      final m = make(t);
      m.session.setQuery('كهف');
      m.service.asks.single.completer.complete(resultOf(0));
      await t.pump(const Duration(seconds: 1));
      m.session.setQuery('الكهف'); // the same two headings
      m.service.asks.last.completer.complete(resultOf(0));
      await t.pump(const Duration(seconds: 1));
      expect(announced, hasLength(1));
    });

    testWidgets('the screen closing (dispose) cancels a waiting announcement', (
      t,
    ) async {
      final m = make(t);
      m.session.setQuery('كهف');
      m.service.asks.single.completer.complete(resultOf(0));
      await t.pump(const Duration(milliseconds: 300));
      m.session.dispose();
      await t.pump(const Duration(seconds: 2));
      expect(announced, isEmpty);
    });
  });

  test('AyahTarget holds the ayah and the page where it begins', () {
    const target = AyahTarget(AyahRef(2, 282), 48);
    expect(target.ref, const AyahRef(2, 282));
    expect(target.page, 48);
  });
}
