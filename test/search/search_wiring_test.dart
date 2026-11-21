// Feature 011, T044: how the one SearchService reaches the app (spec FR-001, FR-022; research D10). MushafApp provides it
// like the other optional services (null in every earlier test, so the index shows no search icon there); main() creates
// ONE, inside _bootApp, with a constructor that reads nothing, and never prepares it: the text of the ayat is read and
// folded only when the search screen is opened (T009, T020). The source checks are in the style of the splash and tips
// wiring tests.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

import '../support/map_bundle.dart';

String read(String path) => File(path).readAsStringSync();

/// Reads the service the way the index will: `context.read<SearchService?>()`.
class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox();
  }
}

void main() {
  /// A service over a bundle that has no file at all and a meta loader that counts its calls: anything the service reads
  /// shows in [bundle].loads or [metaCalls].
  ({SearchService service, MapBundle bundle, List<int> metaCalls})
  quietService() {
    final bundle = MapBundle(const {});
    final metaCalls = <int>[];
    final service = SearchService(
      bundle: bundle,
      meta: () async {
        metaCalls.add(1);
        throw StateError('nothing may read the meta before the search opens');
      },
    );
    addTearDown(service.dispose);
    return (service: service, bundle: bundle, metaCalls: metaCalls);
  }

  Future<void> pumpApp(
    WidgetTester t, {
    SearchService? service,
    required Widget home,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(
      MushafApp(
        wirdRepository: WirdRepository(db),
        mushafRepository: MushafRepository(rootBundle),
        searchService: service,
        home: home,
      ),
    );
    await t.pump();
  }

  group('MushafApp provides the service', () {
    testWidgets(
      'MushafApp(searchService: s) provides context.read<SearchService?>() to the first screen',
      (t) async {
        final q = quietService();
        SearchService? seen;
        await pumpApp(
          t,
          service: q.service,
          home: _Probe((c) => seen = c.read<SearchService?>()),
        );
        expect(seen, isNotNull);
        expect(identical(seen, q.service), isTrue);
      },
    );

    testWidgets('and to a screen pushed over it (the search screen is one)', (
      t,
    ) async {
      final q = quietService();
      SearchService? seen;
      await pumpApp(
        t,
        service: q.service,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _Probe((c) => seen = c.read<SearchService?>()),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      );
      expect(seen, isNull);
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(identical(seen, q.service), isTrue);
    });

    testWidgets(
      'with none it provides null (and asking for it does not throw)',
      (t) async {
        SearchService? seen = quietService().service;
        var asked = false;
        await pumpApp(
          t,
          home: _Probe((c) {
            asked = true;
            seen = c.read<SearchService?>();
          }),
        );
        expect(asked, isTrue);
        expect(seen, isNull);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'an app with none does not shadow a service provided above it (a test host or a harness)',
      (t) async {
        final q = quietService();
        SearchService? seen;
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await t.pumpWidget(
          ListenableProvider<SearchService?>.value(
            value: q.service,
            child: MushafApp(
              wirdRepository: WirdRepository(db),
              mushafRepository: MushafRepository(rootBundle),
              home: _Probe((c) => seen = c.read<SearchService?>()),
            ),
          ),
        );
        await t.pump();
        expect(identical(seen, q.service), isTrue);
      },
    );

    testWidgets(
      'the app, the provider and the first frames read nothing: no file, no meta, the phase stays notStarted',
      (t) async {
        final q = quietService();
        expect(q.service.phase, IndexPhase.notStarted);
        expect(q.bundle.loads, isEmpty);
        expect(q.metaCalls, isEmpty);
        await pumpApp(t, service: q.service, home: const SizedBox());
        await t.pump(const Duration(seconds: 1));
        await t.pumpWidget(const SizedBox());
        expect(q.service.phase, IndexPhase.notStarted);
        expect(q.service.failure, isNull);
        expect(q.bundle.loads, isEmpty);
        expect(q.metaCalls, isEmpty);
      },
    );
  });

  group('the source of app.dart', () {
    final app = read('lib/app.dart');

    test('takes an optional searchService and provides it', () {
      expect(app, contains("import 'search/search_service.dart';"));
      expect(app, contains('final SearchService? searchService;'));
      expect(app, contains('this.searchService,'));
      expect(app, isNot(contains('required this.searchService')));
      // A ChangeNotifier needs the Listenable flavour (provider refuses a plain Provider of a Listenable in debug); like
      // the other optional notifiers of the app (PdfJob, TextSizeSettings, AppLookSettings).
      expect(
        RegExp(
          r'ListenableProvider<SearchService\?>\.value\(\s*value:\s*searchService\s*,?\s*\)',
        ).hasMatch(app),
        isTrue,
      );
    });

    test('never prepares it: the app only hands it on', () {
      expect(app, isNot(contains('.prepare(')));
      expect(app, isNot(contains('.retry(')));
    });
  });

  group('the source of main.dart', () {
    final main = read('lib/main.dart');
    final boot = main.substring(
      main.indexOf('Future<MushafApp> _bootApp()'),
      main.indexOf('/// Starts notifications'),
    );

    test('passes ONE SearchService(bundle: rootBundle, meta: mushafRepository.loadMeta) to the app', () {
      expect(main, contains("import 'search/search_service.dart';"));
      expect(
        RegExp(
          r'searchService:\s*SearchService\(\s*bundle:\s*rootBundle\s*,\s*meta:\s*mushafRepository\.loadMeta\s*,?\s*\)',
        ).hasMatch(main),
        isTrue,
      );
      expect('SearchService('.allMatches(main), hasLength(1));
      expect(boot, contains('searchService: SearchService('));
      expect(boot.indexOf('return MushafApp('), isNonNegative);
      expect(
        boot.indexOf('searchService: SearchService('),
        greaterThan(boot.indexOf('return MushafApp(')),
      );
    });

    test('loads nothing: the loader is handed over uncalled and nothing prepares the service', () {
      expect(main, isNot(contains('.prepare(')));
      expect(main, isNot(contains('.retry(')));
      expect(main, isNot(contains('loadMeta()).then')));
      // `meta: mushafRepository.loadMeta` is the function, not a call: the meta is read when the search opens.
      expect(
        RegExp(r'SearchService\([^)]*loadMeta\(\)').hasMatch(main),
        isFalse,
      );
    });

    test('stays out of the first frame: one runApp, nothing awaited and no search before it', () {
      expect('runApp('.allMatches(main), hasLength(1));
      final head = main.substring(
        main.indexOf('Future<void> main()'),
        main.indexOf('runApp('),
      );
      expect(head, isNot(contains('await ')));
      expect(head, isNot(contains('Search')));
      expect(head, contains('WidgetsFlutterBinding.ensureInitialized();'));
    });
  });
}
