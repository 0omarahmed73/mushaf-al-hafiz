import 'package:flutter/services.dart';

/// The dua's text could not be read (a missing, unreadable or empty asset). The screen then shows a short
/// message in its place (spec FR-019).
class DuaUnavailable implements Exception {
  const DuaUnavailable();

  @override
  String toString() => 'DuaUnavailable';
}

/// The one supplication of the app, read from `assets/khatm/dua.txt` (spec FR-015). The file is paragraphs
/// separated by one blank line; nothing is added, removed or reordered when it is read, so what the owner
/// confirmed is what is shown (SC-006).
class DuaText {
  const DuaText(this.paragraphs);

  /// At least one paragraph, none empty; set once.
  final List<String> paragraphs;

  /// The only dua of the app. There is no second file and no list of duas (Constitution III).
  static const String assetPath = 'assets/khatm/dua.txt';

  /// The text of the file as paragraphs: split at blank lines, the line ends around a paragraph removed, nothing
  /// inside a paragraph touched, empty paragraphs (a longer run of blank lines) dropped.
  static DuaText parse(String text) {
    final paragraphs = <String>[
      for (final raw in text.replaceAll('\r\n', '\n').split('\n\n'))
        if (raw.trim().isNotEmpty) raw.replaceAll(RegExp(r'^\n+|\n+$'), ''),
    ];
    return DuaText(List.unmodifiable(paragraphs));
  }

  /// Reads [assetPath] from [bundle]. Throws [DuaUnavailable] when it cannot be read or holds no paragraph.
  static Future<DuaText> load(AssetBundle bundle) async {
    final String raw;
    try {
      raw = await bundle.loadString(assetPath);
    } catch (_) {
      throw const DuaUnavailable();
    }
    final dua = parse(raw);
    if (dua.paragraphs.isEmpty) throw const DuaUnavailable();
    return dua;
  }

  /// The paragraphs joined by one blank line.
  String get text => paragraphs.join('\n\n');
}
