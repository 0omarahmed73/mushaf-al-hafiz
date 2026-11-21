import 'package:flutter/services.dart';

/// Opens a web link in the phone's browser.
abstract class LinkOpener {
  /// Returns false if the link was not opened (no browser, or not an https link).
  Future<bool> open(String url);
}

/// [LinkOpener] over a small Android channel (see MainActivity), so no extra package is needed.
class PlatformLinkOpener implements LinkOpener {
  const PlatformLinkOpener();

  static const MethodChannel _channel = MethodChannel('app.hafiz.mushaf/links');

  @override
  Future<bool> open(String url) async {
    if (Uri.tryParse(url)?.scheme != 'https') return false;
    try {
      return await _channel.invokeMethod<bool>('open', url) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
