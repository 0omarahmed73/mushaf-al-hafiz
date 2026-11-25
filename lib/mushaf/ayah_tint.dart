import '../ayah/ayah_ref.dart';
import 'models.dart';

/// Ids of every word of [page] (the end marker included) whose ayah is in [marks]; empty when [marks] is empty
/// (feature 013, research D6). It reads the words of the page itself, never a bookmark's stored page, so a surah's first ayah
/// whose title is on the page before is found where its words are. (No ayah crosses a page in this edition.) Colours only: the ids never change the layout.
Set<int> ayahTintIds(PageData page, Set<AyahRef> marks) {
  if (marks.isEmpty) return const {};
  return {
    for (final line in page.lines)
      for (final w in line.words)
        if (marks.contains(AyahRef(w.surah, w.ayah))) w.id,
  };
}
