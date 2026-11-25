import '../wirds/ayah_bookmark_change.dart';
import 'ayah_ref.dart';

/// What the ayah sheet needs from the reader for its bookmark and note rows (feature 013, research D8). Null in tests and
/// screens that do not exercise bookmarks: the sheet then has exactly the rows it had before.
class AyahBookmarkPort {
  const AyahBookmarkPort({
    required this.state,
    required this.toggle,
    required this.saveNote,
    required this.onChange,
  });

  /// Whether the ayah has a bookmark of the current scope and its note, answered synchronously from memory, so the sheet's
  /// first frame already shows the right state (research D5).
  final ({bool bookmarked, String? note}) Function(AyahRef ref) state;

  /// One tap of the bookmark row; null when nothing was written (another write was in progress).
  final Future<AyahBookmarkChange?> Function(AyahRef ref) toggle;

  /// One save of the note field; null when nothing was written (case d of FR-021, or another write in progress).
  final Future<AyahBookmarkChange?> Function(AyahRef ref, String? note)
  saveNote;

  /// The reader shows the message with «تراجع» for [change].
  final void Function(AyahBookmarkChange change) onChange;
}
