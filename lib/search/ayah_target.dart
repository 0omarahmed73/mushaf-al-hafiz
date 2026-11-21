import '../ayah/ayah_ref.dart';

/// What an ayah row of the search screen hands back to the index and the reader: the ayah and the page where it begins
/// (spec FR-011, FR-013; research D4). A surah row hands back the surah's first page as an `int`, the index's own value.
class AyahTarget {
  const AyahTarget(this.ref, this.page);

  final AyahRef ref;
  final int page;
}
