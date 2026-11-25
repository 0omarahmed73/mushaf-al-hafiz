import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../ayah/ayah_ref.dart';
import '../mushaf/ayah_bookmark_strings.dart';
import '../mushaf/models.dart';
import '../search/ayah_target.dart';
import '../theme.dart';
import 'today_panel.dart';
import 'wird_repository.dart';

/// «علامات»: adds a bookmark on the page being shown (with an optional note) and lists every
/// bookmark, newest first, with its page, note and wird name or «عامة». Tapping one pops the sheet
/// with its page; swiping one away deletes it (spec FR-033). An ayah bookmark (feature 013) is a row of the same list that
/// names its ayah and pops an [AyahTarget] instead of the page.
class BookmarksSheet extends StatefulWidget {
  const BookmarksSheet({
    super.key,
    required this.page,
    required this.ownerName,
    required this.onAdd,
    this.meta,
  });

  /// The page a new bookmark would be on.
  final int page;

  /// The wird a new bookmark would belong to, or null when it would be general («عامة»).
  final String? ownerName;

  final Future<void> Function(String? note) onAdd;

  /// The surah names of ayah rows (feature 013); without it an ayah row names its surah by number.
  final MushafMeta? meta;

  @override
  State<BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends State<BookmarksSheet> {
  late final WirdRepository _repo = context.read<WirdRepository>();
  late final Stream<List<BookmarkEntry>> _bookmarks = _repo.watchBookmarks();

  Future<void> _add() async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) =>
          _NoteDialog(page: widget.page, ownerName: widget.ownerName),
    );
    if (note != null) await widget.onAdd(note);
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: look.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('علامات', style: headingStyle(24, look.heading)),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('bookmark-add'),
                onPressed: _add,
                icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                label: Text('إضافة علامة للصفحة ${widget.page}'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(look.buttonRadius(14)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                child: Text(
                  widget.ownerName == null
                      ? 'ستُحفظ كعلامة عامة'
                      : 'ستُحفظ ضمن: ${widget.ownerName}',
                  style: TextStyle(fontSize: 12, color: look.textSecondary),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<BookmarkEntry>>(
                  stream: _bookmarks,
                  builder: (context, snapshot) {
                    final entries = snapshot.data;
                    if (entries == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد علامات بعد',
                          style: TextStyle(color: look.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      key: const ValueKey('bookmark-list'),
                      itemCount: entries.length,
                      itemBuilder: (context, i) => _BookmarkTile(
                        entry: entries[i],
                        meta: widget.meta,
                        onOpen: () =>
                            Navigator.of(context).pop(_target(entries[i])),
                        onDelete: () =>
                            _repo.removeBookmark(entries[i].bookmark.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a tap on a row hands back: the page of a page bookmark, as before, or the ayah of an ayah bookmark.
Object _target(BookmarkEntry entry) {
  final b = entry.bookmark;
  final surah = b.surah, ayah = b.ayah;
  if (surah == null || ayah == null) return b.page;
  return AyahTarget(AyahRef(surah, ayah), b.page);
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
    this.meta,
  });

  final BookmarkEntry entry;
  final MushafMeta? meta;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(look.rowRadius(14));
    final b = entry.bookmark;
    final surah = b.surah, ayah = b.ayah;
    final isAyah = surah != null && ayah != null;
    final surahName = !isAyah ? '' : meta?.surah(surah).name ?? '$surah';
    final owner = entry.wirdName ?? kAyahOwnerGeneral;
    final swipe = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: scheme.error, borderRadius: radius),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: AlignmentDirectional.centerEnd,
      child: Icon(Icons.delete_outline, color: scheme.onError),
    );
    return Dismissible(
      key: ValueKey('bookmark-${b.id}'),
      direction: DismissDirection.horizontal,
      background: swipe,
      secondaryBackground: swipe,
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: look.cardFill,
          borderRadius: radius,
          child: _ayahSemantics(
            isAyah: isAyah,
            label: isAyah ? kAyahRowLabel(surahName, ayah, b.page, owner) : '',
            onTap: onOpen,
            child: InkWell(
              borderRadius: radius,
              onTap: onOpen,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: look.cardInk),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: LayoutBuilder(
                    builder: (context, row) => Row(
                      children: [
                        // The ayah row's own mark (feature 013): an icon that a page row does not have.
                        if (isAyah)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 12),
                            child: Icon(
                              Icons.auto_stories_outlined,
                              key: ValueKey('bookmark-ayah-icon-${b.id}'),
                              size: 22,
                              color: look.cardInk,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isAyah)
                                _excluded(
                                  Text(
                                    kAyahRowTitle(surahName, ayah),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              _excluded(
                                Text(
                                  'ص ${b.page}',
                                  style: isAyah
                                      ? TextStyle(
                                          fontSize: 13,
                                          color: look.cardMuted,
                                        )
                                      : const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                isAyah,
                              ),
                              if (b.note != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    b.note!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: look.cardMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // An ayah row has an icon more: there its tag may shrink and wrap, so a narrow phone with a large
                        // font never pushes «ص P» out (a page row is as before).
                        if (isAyah)
                          Flexible(
                            child: _excluded(CardTag(entry.wirdName ?? 'عامة')),
                          )
                        else
                          // A page row is as before while its tag takes at most half the row. A longer one (a long wird
                          // name on a narrow phone with a large system font) wraps inside that half, so «ص P» is never
                          // squeezed out.
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: row.maxWidth / 2,
                            ),
                            child: CardTag(entry.wirdName ?? 'عامة'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// An ayah row is one button for a screen reader, named «علامة على سورة X آية N، صفحة P، …»; its note is still read. A page
  /// row is as before.
  static Widget _ayahSemantics({
    required bool isAyah,
    required String label,
    required VoidCallback onTap,
    required Widget child,
  }) => isAyah
      ? Semantics(
          container: true,
          button: true,
          label: label,
          onTap: onTap,
          child: child,
        )
      : child;

  /// The parts of an ayah row its label already says; a page row's parts are as before.
  static Widget _excluded(Widget child, [bool exclude = true]) =>
      exclude ? ExcludeSemantics(child: child) : child;
}

/// Asks for the optional note. Pops the note's text (possibly empty) to save, or null to cancel.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.page, required this.ownerName});

  final int page;
  final String? ownerName;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('علامة على الصفحة ${widget.page}'),
      content: TextField(
        key: const ValueKey('bookmark-note'),
        controller: _note,
        autofocus: true,
        maxLength: 200,
        minLines: 1,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'ملاحظة (اختياري)',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          key: const ValueKey('bookmark-save'),
          onPressed: () => Navigator.of(context).pop(_note.text),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
