import 'package:material_ui/material_ui.dart';

import '../../mushaf/ayah_bookmark_strings.dart';

/// The longest note a bookmark keeps (data-model.md Bookmarks.note; the limit of a page bookmark's note).
const int kAyahNoteMaxLength = 200;

/// Opens the note field «ملاحظة للآية» titled [title] (feature 013; spec FR-015, FR-021; research D9), with
/// [initialNote] in the field and the focus in it. The line under the field says what saving does, chosen by
/// [bookmarkExists] (whether the ayah has a bookmark of the scope now).
///
/// true = saved (the dialog closed); false/null = cancelled by «إلغاء», the back gesture or a tap outside, and nothing
/// was called. [onSave] gets the typed text (possibly empty) and does the write; if it throws, the dialog stays open
/// with the typed text and shows «تعذّر الحفظ، حاول مرة أخرى» under the field.
Future<bool?> showAyahNoteDialog(
  BuildContext context, {
  required String title,
  required String? initialNote,
  required bool bookmarkExists,
  required Future<void> Function(String text) onSave,
}) => showDialog<bool>(
  context: context,
  builder: (_) => _AyahNoteDialog(
    title: title,
    initialNote: initialNote,
    bookmarkExists: bookmarkExists,
    onSave: onSave,
  ),
);

/// Shows the whole [note] to read, titled [title] (spec FR-028). true = «تعديل» was tapped (the caller opens the note
/// field); false/null = «إغلاق», the back gesture or a tap outside. Nothing is written here.
Future<bool?> showAyahNoteView(
  BuildContext context, {
  required String title,
  required String note,
}) => showDialog<bool>(
  context: context,
  builder: (context) {
    const buttonSize = Size(64, 48);
    return AlertDialog(
      key: const ValueKey('ayah-note-view'),
      // The title and a long note scroll together on a narrow phone with a large system font; the buttons stay below.
      scrollable: true,
      title: Text(title),
      content: Text(
        note,
        key: const ValueKey('ayah-note-view-text'),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actions: [
        TextButton(
          key: const ValueKey('ayah-note-view-close'),
          style: TextButton.styleFrom(minimumSize: buttonSize),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(kAyahNoteClose),
        ),
        TextButton(
          key: const ValueKey('ayah-note-view-edit'),
          style: TextButton.styleFrom(minimumSize: buttonSize),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(kAyahNoteEdit),
        ),
      ],
    );
  },
);

class _AyahNoteDialog extends StatefulWidget {
  const _AyahNoteDialog({
    required this.title,
    required this.initialNote,
    required this.bookmarkExists,
    required this.onSave,
  });

  final String title;
  final String? initialNote;
  final bool bookmarkExists;
  final Future<void> Function(String text) onSave;

  @override
  State<_AyahNoteDialog> createState() => _AyahNoteDialogState();
}

class _AyahNoteDialogState extends State<_AyahNoteDialog> {
  late final TextEditingController _note = TextEditingController(
    text: widget.initialNote ?? '',
  );
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(_note.text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const buttonSize = Size(64, 48);
    return AlertDialog(
      // The title scrolls with the field: on a narrow phone with a large system font the title alone is several lines, and
      // the field and the two buttons must still be whole and reachable.
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('ayah-note-field'),
            controller: _note,
            autofocus: true,
            maxLength: kAyahNoteMaxLength,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: kAyahNoteField,
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.bookmarkExists ? kAyahNoteHintExisting : kAyahNoteHintNew,
            style: theme.textTheme.bodySmall,
          ),
          if (_failed) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                kAyahNoteFailed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('ayah-note-cancel'),
          style: TextButton.styleFrom(minimumSize: buttonSize),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(kAyahNoteCancel),
        ),
        TextButton(
          key: const ValueKey('ayah-note-save'),
          style: TextButton.styleFrom(minimumSize: buttonSize),
          onPressed: _saving ? null : _save,
          child: const Text(kAyahNoteSave),
        ),
      ],
    );
  }
}
