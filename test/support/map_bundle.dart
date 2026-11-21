import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An [AssetBundle] over a map of path → text that counts every load (no caching of its own).
class MapBundle extends AssetBundle {
  MapBundle(this.files);

  final Map<String, String> files;
  final List<String> loads = [];

  @override
  Future<ByteData> load(String key) async {
    loads.add(key);
    final text = files[key];
    if (text == null) throw FlutterError('Unable to load asset: "$key".');
    final bytes = Uint8List.fromList(utf8.encode(text));
    return ByteData.sublistView(bytes);
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(await loadString(key));
}
