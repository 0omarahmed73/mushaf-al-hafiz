import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import 'today_panel.dart';
import 'wird_repository.dart';

/// «علامات»: adds a bookmark on the page being shown (with an optional note) and lists every
/// bookmark, newest first, with its page, note and wird name or «عامة». Tapping one pops the sheet
/// with its page; swiping one away deletes it (spec FR-033).
class BookmarksSheet extends StatefulWidget {
  const BookmarksSheet({
    super.key,
    required this.page,
    required this.ownerName,
    required this.onAdd,
  });

  /// The page a new bookmark would be on.
  final int page;

  /// The wird a new bookmark would belong to, or null when it would be general («عامة»).
  final String? ownerName;

  final Future<void> Function(String? note) onAdd;

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
                        onOpen: () =>
                            Navigator.of(context).pop(entries[i].bookmark.page),
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

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
  });

  final BookmarkEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(look.rowRadius(14));
    final b = entry.bookmark;
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ص ${b.page}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
                    CardTag(entry.wirdName ?? 'عامة'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
