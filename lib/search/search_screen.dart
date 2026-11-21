/// The search screen (feature 011; contracts/ui.md "The screen", "States"; spec FR-002, FR-004, FR-008, FR-009, FR-010, FR-014):
/// one field and the two groups of results under it, the surah names from one letter and the ayat from two. Pops an `int` (a
/// surah's first page, the index's own value) or an `AyahTarget`, or nothing when it is left with back.
///
/// The screen holds the field's text, the list's scroll offset and the [SearchSession] in its State, so a rotation keeps them
/// and closing it forgets them (spec FR-017). It reads the `SearchService` and the `MushafRepository` from the Provider tree.
library;

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../mushaf/models.dart';
import '../mushaf/mushaf_repository.dart';
import 'search_rows.dart';
import 'search_service.dart';
import 'search_session.dart';
import 'search_strings.dart';
import 'search_trace.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.trace, this.bench});

  /// Receives the measurement lines of the screen (research D9): `SEARCH query` for each query and, with [bench], the 20
  /// `SEARCHBENCH` lines. Null (the app): the log under `--dart-define=SEARCH_TRACE=true` or `SEARCH_BENCH=true`, nothing
  /// otherwise. A test passes its own.
  final void Function(String line)? trace;

  /// Runs the 20 queries of SC-004 through the session when the screen opens. Null (the app): `SearchTrace.bench`.
  final bool? bench;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  late final SearchService _service;
  SearchSession? _session;

  /// The 114 surahs (the names as the index writes them); empty until the session opens.
  List<SurahInfo> _surahs = const [];

  /// Where the measurement lines go; null in a normal build, where nothing is measured.
  void Function(String line)? _trace;

  /// The query being timed (measurement builds only): since the field changed, its length, and the ayah group shown then.
  Stopwatch? _queryWatch;
  int _queryLength = 0;
  AyahGroup? _groupBefore;

  /// The text the list was last asked about.
  String _asked = '';

  /// The route the screen is shown in.
  ModalRoute<Object?>? _route;

  /// A result was chosen: the route is popping and a second tap in the same frame must not pop again.
  bool _chosen = false;

  @override
  void initState() {
    super.initState();
    final service = context.read<SearchService?>();
    if (service == null) {
      throw StateError('SearchScreen needs a SearchService above it');
    }
    _service = service;
    _trace =
        widget.trace ??
        (SearchTrace.enabled || SearchTrace.bench ? SearchTrace.emit : null);
    // The first search of the run prepares the ayah text. The service notifies at once and the provider above listens to it,
    // so it is started after this frame, never while the route builds; a preparation that runs or has ended is left alone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _service.phase == IndexPhase.notStarted) {
        unawaited(_service.prepare());
      }
    });
    unawaited(_openSession(context.read<MushafRepository>()));
  }

  /// The session needs the 114 names; the field and the keyboard do not wait for them.
  Future<void> _openSession(MushafRepository repository) async {
    List<SurahInfo> surahs;
    try {
      surahs = (await repository.loadMeta()).surahs;
    } on Object {
      surahs = const [];
    }
    if (!mounted) return;
    _surahs = surahs;
    final session = SearchSession(
      service: _service,
      surahs: surahs,
      onAnnounce: _announce,
    );
    // what was typed before the names were read
    session.setQuery(_controller.text);
    if (_trace != null) session.addListener(_onAnswer);
    setState(() => _session = session);
    if (widget.bench ?? SearchTrace.bench) unawaited(_runBench(session));
  }

  /// Measurement builds: the answer to the query being timed has arrived; its line is printed after the frame that shows it.
  void _onAnswer() {
    final watch = _queryWatch;
    final group = _session?.view.ayah;
    if (watch == null || group is! AyahResults) return;
    if (identical(group, _groupBefore)) return;
    _queryWatch = null;
    final length = _queryLength;
    final total = group.result.total;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trace?.call(
        SearchTrace.queryLine(length, total, watch.elapsedMilliseconds),
      );
    });
  }

  /// Bench builds: the 20 queries of SC-004, one after the other, through the session (the phone's keyboard cannot be driven
  /// with Arabic), each with its `SEARCHBENCH` line; then the field's own text again.
  Future<void> _runBench(SearchSession session) async {
    await _service.prepare();
    if (_service.phase != IndexPhase.ready) return;
    for (var i = 0; i < SearchTrace.benchQueries.length; i++) {
      if (!mounted) return;
      final before = session.view.ayah;
      final answered = Completer<AyahResults>();
      void listen() {
        final group = session.view.ayah;
        if (group is AyahResults &&
            !identical(group, before) &&
            !answered.isCompleted) {
          answered.complete(group);
        }
      }

      final watch = Stopwatch()..start();
      session.addListener(listen);
      session.setQuery(SearchTrace.benchQueries[i]);
      final group = await answered.future;
      session.removeListener(listen);
      _trace?.call(
        SearchTrace.benchLine(
          i + 1,
          group.result.total,
          watch.elapsedMilliseconds,
        ),
      );
    }
    if (mounted) session.setQuery(_controller.text);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  /// The screen reader is told nothing once the screen is closing (a popped route stays mounted while it leaves).
  void _announce(String text) {
    if (!mounted || _chosen || !(_route?.isCurrent ?? true)) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        Directionality.of(context),
      ),
    );
  }

  @override
  void dispose() {
    _session?.dispose();
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    if (text == _asked) return;
    _asked = text;
    if (_trace != null) {
      _queryWatch = Stopwatch()..start();
      _queryLength = text.length;
      _groupBefore = _session?.view.ayah;
    }
    _session?.setQuery(text);
    // the answers to a new query start at their top, not where the answers to the old one were scrolled to
    if (_scroll.hasClients && _scroll.offset > 0) _scroll.jumpTo(0);
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
    _focus.requestFocus();
  }

  void _choose(Object value) {
    if (_chosen) return;
    _chosen = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kSearchLabel)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => TextField(
                key: const ValueKey('search-field'),
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                maxLines: 1,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  labelText: kSearchFieldLabel,
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          key: const ValueKey('search-clear'),
                          tooltip: kSearchClear,
                          icon: const Icon(Icons.close),
                          onPressed: _clear,
                        ),
                ),
              ),
            ),
          ),
          Expanded(child: _results()),
        ],
      ),
    );
  }

  Widget _results() {
    final session = _session;
    if (session == null) return _list(_nothingTyped);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => _list(session.view),
    );
  }

  static const SearchView _nothingTyped = SearchView(
    surahs: [],
    ayah: AyahHint(),
    letters: 0,
  );

  Widget _list(SearchView view) {
    final items = _items(view);
    return ListView.builder(
      key: const ValueKey('search-results'),
      controller: _scroll,
      itemCount: items.length,
      itemBuilder: (context, i) => items[i],
    );
  }

  /// The rows and lines of [view] in the order of contracts/ui.md "The screen": the surah group, then the ayah group or the
  /// line that stands for it.
  List<Widget> _items(SearchView view) {
    final items = <Widget>[];
    if (view.surahs.isNotEmpty) {
      final n = view.surahs.length;
      items.add(
        SearchHeading(
          key: const ValueKey('search-heading-surahs'),
          text: kSurahHeading(n),
          semantics: kSurahHeadingSemantics(n),
        ),
      );
      for (final surah in view.surahs) {
        items.add(
          SurahRow(
            key: ValueKey('surah-row-${surah.number}'),
            surah: surah,
            onChosen: _choose,
          ),
        );
      }
    }
    switch (view.ayah) {
      case AyahHint():
        items.add(const SearchLine(text: kSearchHint));
      case AyahNeedsTwo():
        items.add(const SearchLine(text: kSearchNeedTwo));
      case AyahPreparing():
        items.add(const SearchLine(text: kSearchPreparing));
      case AyahFailed():
        items.add(const SearchLine(text: kSearchFailed));
        items.add(SearchRetryButton(onPressed: () => _session?.retry()));
      case AyahSearching():
        break;
      case AyahResults(:final result):
        if (view.none) {
          items.add(
            const SearchLine(text: kSearchNone, advice: kSearchNoneAdvice),
          );
        } else if (result.total > 0) {
          items.add(
            SearchHeading(
              key: const ValueKey('search-heading-ayat'),
              text: kAyahHeading(result.total),
              semantics: kAyahHeadingSemantics(result.total),
            ),
          );
          for (final hit in result.hits) {
            items.add(
              AyahRow(
                key: ValueKey('ayah-row-${hit.ref.key}'),
                hit: hit,
                surahName: _surahs[hit.ref.surah - 1].name,
                onChosen: _choose,
              ),
            );
          }
          if (result.tooMany) {
            items.add(
              const SearchLine(
                key: ValueKey('search-more-line'),
                text: kSearchTooMany,
              ),
            );
          }
        }
    }
    return items;
  }
}
