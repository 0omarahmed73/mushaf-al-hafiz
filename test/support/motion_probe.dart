// Helpers of the feature 010 measurements (test/motion). They only observe: nothing here changes what the app does.
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One printed line of a measurement. `flutter test --reporter expanded` shows it; research.md quotes these lines.
void motionLog(String line) => print('MOTION $line');

/// An [AssetBundle] over the project's own `assets/` folder that counts loads and times nothing itself. The tests run
/// with the project folder as the working directory, so `assets/mushaf/pages/p001.json` is a plain file.
class FileBundle extends AssetBundle {
  final List<String> loads = [];

  @override
  Future<ByteData> load(String key) async {
    loads.add(key);
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(await loadString(key));
}

/// Mean, median, 95th percentile and maximum of a list of millisecond readings.
class MotionStats {
  MotionStats(Iterable<double> readings) : _ms = readings.toList()..sort() {
    assert(_ms.isNotEmpty);
  }

  final List<double> _ms;

  int get count => _ms.length;
  double get mean => _ms.fold<double>(0, (a, b) => a + b) / _ms.length;
  double get median => percentile(50);
  double get p95 => percentile(95);
  double get max => _ms.last;
  double get min => _ms.first;

  /// Nearest-rank percentile.
  double percentile(double p) {
    final rank = (p / 100 * _ms.length).ceil().clamp(1, _ms.length);
    return _ms[rank - 1];
  }

  @override
  String toString() =>
      'n=$count mean=${mean.toStringAsFixed(2)} ms median=${median.toStringAsFixed(2)} '
      'p95=${p95.toStringAsFixed(2)} max=${max.toStringAsFixed(2)}';
}

/// Milliseconds of [Stopwatch.elapsedMicroseconds].
double ms(Stopwatch s) => s.elapsedMicroseconds / 1000;

/// Counts how many times each kind of widget is rebuilt (built again, or built the first time) while [phase] is
/// set, through the framework's own `debugOnRebuildDirtyWidget` hook (asserts are on in `flutter test`).
class RebuildProbe {
  final Map<String, Map<String, int>> _byPhase = {};
  String? phase;

  /// Starts counting; call [stop] (or register it with `addTearDown`) when done.
  void start() {
    assert(debugOnRebuildDirtyWidget == null, 'another probe is running');
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      final p = phase;
      if (p == null) return;
      final counts = _byPhase.putIfAbsent(p, () => {});
      final name = element.widget.runtimeType.toString();
      counts[name] = (counts[name] ?? 0) + 1;
    };
  }

  void stop() => debugOnRebuildDirtyWidget = null;

  int count(String phase, String widgetType) =>
      _byPhase[phase]?[widgetType] ?? 0;

  /// Rebuilds of every widget whose type name starts with [prefix] (generic types print their arguments).
  int countPrefix(String phase, String prefix) => (_byPhase[phase] ?? {})
      .entries
      .where((e) => e.key.startsWith(prefix))
      .fold<int>(0, (a, e) => a + e.value);

  /// Rebuilds in every phase whose name starts with [phasePrefix], summed.
  int countAll(String phasePrefix, String widgetType) => _byPhase.entries
      .where((e) => e.key.startsWith(phasePrefix))
      .fold<int>(0, (a, e) => a + (e.value[widgetType] ?? 0));

  /// Rebuilds of [widgetType] in every phase so far.
  int total(String widgetType) =>
      _byPhase.values.fold<int>(0, (a, m) => a + (m[widgetType] ?? 0));

  List<String> get phases => _byPhase.keys.toList()..sort();

  /// All counts of [phase], biggest first.
  List<MapEntry<String, int>> top(String phase, {int limit = 12}) {
    final entries = (_byPhase[phase] ?? {}).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// One log line per phase: the widgets in [watch] with their counts.
  void log(String scenario, List<String> watch) {
    for (final entry in _byPhase.entries) {
      final parts = [for (final w in watch) '$w=${entry.value[w] ?? 0}'];
      final total = entry.value.values.fold<int>(0, (a, b) => a + b);
      motionLog(
        '$scenario phase=${entry.key} rebuilds: ${parts.join(' ')} total=$total',
      );
    }
  }
}

/// Number of elements in the subtree below [root] (the page's widget density).
int subtreeSize(Element root) {
  var n = 0;
  void visit(Element e) {
    n++;
    e.visitChildren(visit);
  }

  visit(root);
  return n;
}

/// Sample of page numbers spread over the Mushaf: the first pages, dense and sparse ones, the last.
List<int> samplePages([int step = 29]) =>
    [1, 2, for (var p = step; p <= 604; p += step) p, 604]..sort();

double roundTo(double v, int digits) {
  final f = math.pow(10, digits);
  return (v * f).round() / f;
}
