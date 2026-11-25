import '../ayah/ayah_ref.dart';
import 'db.dart';

/// What one tap of the ayah sheet's bookmark row, or one save of the note, did (feature 013, data-model.md
/// `AyahBookmarkChange`).
enum AyahChangeKind {
  added,
  removed,
  createdWithNote,
  noteReplaced,
  noteCleared,
}

/// The value the message keeps so that «تراجع» undoes exactly that tap or save. Exactly one of the three payloads is set
/// for each kind: [addedId] for [AyahChangeKind.added] and [AyahChangeKind.createdWithNote], [removed] for
/// [AyahChangeKind.removed], [before] for [AyahChangeKind.noteReplaced] and [AyahChangeKind.noteCleared].
class AyahBookmarkChange {
  const AyahBookmarkChange({
    required this.kind,
    required this.ref,
    required this.page,
    this.addedId,
    this.removed = const [],
    this.before = const [],
  });

  final AyahChangeKind kind;
  final AyahRef ref;

  /// The page where the ayah begins.
  final int page;

  /// The new row's id.
  final int? addedId;

  /// The rows the tap deleted.
  final List<Bookmark> removed;

  /// The id and the previous note of every row the save changed.
  final List<({int id, String? note})> before;
}
