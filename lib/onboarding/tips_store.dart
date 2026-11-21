import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../wirds/wird_repository.dart';

/// The key of the one stored fact of the first-run tips, in the settings table (data-model.md "The flag: tipsSeen").
/// It travels in the backup like every other setting (research D5).
const String kTipsSeenKey = 'tipsSeen';

/// Reads and writes whether the tips were finished or skipped. One query to read, one write to store: it never
/// listens to the database (research D2, a drift stream in the fake-async zone hangs tests).
class TipsStore {
  const TipsStore(this._repository);

  final WirdRepository _repository;

  /// The store of the app's repository, or null when [context] has no `Provider<WirdRepository>` above it (a screen
  /// built without the app, as in a test): the tips then still show, and nothing is stored.
  static TipsStore? maybeOf(BuildContext context) {
    try {
      return TipsStore(Provider.of<WirdRepository>(context, listen: false));
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// The rule: only exactly `'true'` means seen; a missing row or any other value means not seen (research D3).
  static bool isSeen(String? stored) => stored == 'true';

  /// One read, no stream. Throws what the repository throws; the caller decides what a failure means.
  Future<bool> seen() async =>
      isSeen(await _repository.readSetting(kTipsSeenKey));

  /// Stores that the tips were seen.
  Future<void> markSeen() => _repository.writeSetting(kTipsSeenKey, 'true');
}
