import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../look/look_settings.dart';
import '../../mushaf/ayah_bookmark_strings.dart';
import '../../mushaf/models.dart';
import '../../mushaf/page_look.dart';
import '../../pdf/pdf_job.dart';
import '../../theme.dart';
import '../../wirds/ayah_bookmark_change.dart';
import '../ayah_bookmark_port.dart';
import '../ayah_ref.dart';
import '../ayah_repository.dart';
import '../failures.dart';
import '../share_service.dart';
import '../../render/page_renderer.dart';
import '../page_picture_action.dart';
import '../share_text.dart';
import 'ayah_note_dialog.dart';
import 'meanings_view.dart';
import 'tafsir_view.dart';
import 'translation_view.dart';

/// Opens the menu of [ref] as a bottom sheet and completes when it is closed. [page] is the Mushaf page the
/// menu was opened on (the one «مشاركة الصفحة كصورة» shares). Does nothing when the app has no ayah data or
/// share service (tests that do not need them). With [bookmarks] (the reader always gives one) the sheet also has the
/// ayah's bookmark row and its note row (feature 013).
Future<void> showAyahSheet(
  BuildContext context, {
  required AyahRef ref,
  required MushafMeta meta,
  required int page,
  AyahBookmarkPort? bookmarks,
}) {
  final repo = context.read<AyahRepository?>();
  final share = context.read<ShareService?>();
  if (repo == null || share == null) return Future<void>.value();
  final renderer = context.read<PageRenderer?>();
  final files = context.read<TempShareFiles?>();
  final pdfJob = context.read<PdfJob?>();
  final look = _pageLookOf(context);
  final picture = renderer == null || files == null
      ? null
      : PagePictureAction(
          renderer: renderer,
          files: files,
          share: share,
          look: look,
        );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.look.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AyahSheet(
      ref: ref,
      meta: meta,
      page: page,
      repository: repo,
      share: share,
      pictureAction: picture,
      pdfJob: pdfJob,
      look: look,
      bookmarks: bookmarks,
    ),
  );
}

/// How the page picture and the surah PDF are drawn: in the look the owner chose, read when the menu opens; Emerald &
/// Gold when the app has no look setting (tests that do not need it).
PageLook _pageLookOf(BuildContext context) {
  try {
    return context.read<AppLookSettings?>()?.pageLook ?? PageLook.screen;
  } on ProviderNotFoundException {
    return PageLook.screen;
  }
}

/// The menu of one ayah: headed «سورة X · آية N», with a row per action. Later stories add their rows
/// (tafsir, translation, word meanings, page picture, surah PDF) here.
class AyahSheet extends StatefulWidget {
  const AyahSheet({
    super.key,
    required this.ref,
    required this.meta,
    required this.page,
    required this.repository,
    required this.share,
    this.pictureAction,
    this.pdfJob,
    this.look = PageLook.screen,
    this.bookmarks,
  });

  final AyahRef ref;
  final MushafMeta meta;

  /// The Mushaf page the menu was opened on.
  final int page;
  final AyahRepository repository;
  final ShareService share;

  /// Null when the app has no page renderer: the picture row is then not offered.
  final PagePictureAction? pictureAction;

  /// Null when the app has no PDF job: the surah PDF row is then not offered.
  final PdfJob? pdfJob;

  /// The look the surah PDF is prepared in; the picture action carries its own.
  final PageLook look;

  /// The reader's bookmarks of this ayah (feature 013); null: no bookmark row and no note row.
  final AyahBookmarkPort? bookmarks;

  @override
  State<AyahSheet> createState() => _AyahSheetState();
}

enum _View { menu, tafsir, translation, meanings }

class _AyahSheetState extends State<AyahSheet> {
  late final ShareTextBuilder _texts = ShareTextBuilder(widget.meta);
  _View _view = _View.menu;
  String? _status;
  bool _busy = false;

  void _setStatus(String? message) {
    if (mounted) setState(() => _status = message);
  }

  void _show(_View view) => setState(() {
    _view = view;
    _status = null;
  });

  /// Hands [text] to the share sheet. A dismissed share sheet is not an error, so nothing is shown for it;
  /// a failure shows its Arabic message and leaves the sheet usable.
  Future<void> _share(Future<String> Function() text) async {
    _setStatus(null);
    try {
      await widget.share.shareText(await text());
    } catch (error) {
      _setStatus(
        error is ShareFailure
            ? error.message
            : const ShareFailure(ShareFailureKind.couldNotShare).message,
      );
    }
  }

  /// «مشاركة»: the ayah's exact words and its reference through the share sheet.
  Future<void> _shareAyah() => _share(
    () async =>
        _texts.ayah(widget.ref, await widget.repository.words(widget.ref)),
  );

  /// «مشاركة الصفحة كصورة»: one PNG of the page the menu was opened on.
  Future<void> _sharePicture() async {
    final action = widget.pictureAction;
    if (action == null || _busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action.run(
        widget.page,
        onSlow: () => _setStatus('جارٍ تجهيز الصورة'),
      );
      _setStatus(null);
    } catch (error) {
      _setStatus(
        error is ShareFailure
            ? error.message
            : const ShareFailure(ShareFailureKind.couldNotPrepare).message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The bookmark row (feature 013): closes the sheet and toggles the ayah's bookmark of the current scope; the reader
  /// shows the message. A failed write shows nothing (spec FR-006, edge cases).
  Future<void> _toggleBookmark(AyahBookmarkPort port) async {
    final write = port.toggle(widget.ref);
    Navigator.of(context).pop();
    try {
      final change = await write;
      if (change != null) port.onChange(change);
    } catch (error) {
      debugPrint('ayah bookmark failed: $error');
    }
  }

  /// The note row «ملاحظة للآية» (feature 013; spec FR-015, FR-021): opens the note field over the sheet with the note the
  /// ayah's bookmark of the scope has now. Cancelling leaves the sheet open and writes nothing. A save writes through the
  /// reader, then closes the sheet and the reader shows the message; a save that wrote nothing (an empty note on an ayah
  /// with no bookmark) closes the sheet with no message. A failed write stays in the field, which says so.
  Future<void> _editNote(AyahBookmarkPort port) async {
    final state = port.state(widget.ref);
    AyahBookmarkChange? change;
    final saved = await showAyahNoteDialog(
      context,
      title: kAyahNoteTitle(
        widget.meta.surah(widget.ref.surah).name,
        widget.ref.ayah,
      ),
      initialNote: state.note,
      bookmarkExists: state.bookmarked,
      onSave: (text) async => change = await port.saveNote(widget.ref, text),
    );
    if (saved != true || !mounted) return;
    Navigator.of(context).pop();
    final done = change;
    if (done != null) port.onChange(done);
  }

  /// «عرض الملاحظة» (spec FR-028): shows the whole note over the sheet; «تعديل» goes on to the note field as the note row
  /// does, «إغلاق» leaves the sheet open. Reading writes nothing.
  Future<void> _showNote(AyahBookmarkPort port, String note) async {
    final edit = await showAyahNoteView(
      context,
      title: kAyahNoteTitle(
        widget.meta.surah(widget.ref.surah).name,
        widget.ref.ayah,
      ),
      note: note,
    );
    if (edit == true && mounted) await _editNote(port);
  }

  /// «مشاركة السورة PDF»: starts the PDF of this ayah's surah in the reader's job and closes the menu; the
  /// reader's strip then shows the progress.
  void _startPdf() {
    final job = widget.pdfJob;
    if (job == null) return;
    if (job.start(widget.ref.surah, look: widget.look)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // System back leaves a view for the menu first; only from the menu does it close the sheet.
      canPop: _view == _View.menu,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _show(_View.menu);
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: switch (_view) {
            _View.menu => _menu(),
            _View.tafsir => TafsirView(
              ref: widget.ref,
              repository: widget.repository,
              onBack: () => _show(_View.menu),
              onShare: (text) =>
                  _share(() async => _texts.tafsir(widget.ref, text)),
              status: _status,
            ),
            _View.meanings => MeaningsView(
              ref: widget.ref,
              repository: widget.repository,
              onBack: () => _show(_View.menu),
            ),
            _View.translation => TranslationView(
              ref: widget.ref,
              repository: widget.repository,
              onBack: () => _show(_View.menu),
              onShare: (text) =>
                  _share(() async => _texts.translation(widget.ref, text)),
              status: _status,
            ),
          },
        ),
      ),
    );
  }

  Widget _menu() {
    final look = context.look;
    final name = widget.meta.surah(widget.ref.surah).name;
    final status = _status;
    // Scrolls when a small phone with large text cannot show every row; it looks the same when they all fit.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            'سورة $name · آية ${widget.ref.ayah}',
            style: headingStyle(22, look.heading),
          ),
          const SizedBox(height: 12),
          SheetRow(
            key: const ValueKey('ayah-share'),
            icon: Icons.share_outlined,
            label: 'مشاركة',
            onTap: _shareAyah,
          ),
          SheetRow(
            key: const ValueKey('ayah-tafsir'),
            icon: Icons.menu_book_outlined,
            label: 'التفسير',
            onTap: () => _show(_View.tafsir),
          ),
          SheetRow(
            key: const ValueKey('ayah-translation'),
            icon: Icons.translate,
            label: 'الترجمة',
            onTap: () => _show(_View.translation),
          ),
          SheetRow(
            key: const ValueKey('ayah-meanings'),
            icon: Icons.abc,
            label: 'معاني الكلمات',
            onTap: () => _show(_View.meanings),
          ),
          if (widget.bookmarks case final port?) ..._bookmarkRows(port),
          if (widget.pictureAction != null || widget.pdfJob != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(
                'الصفحة والسورة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: look.textSecondary,
                ),
              ),
            ),
            if (widget.pictureAction != null)
              SheetRow(
                key: const ValueKey('ayah-page-picture'),
                icon: Icons.image_outlined,
                label: 'مشاركة الصفحة كصورة',
                onTap: _busy ? null : _sharePicture,
              ),
            if (widget.pdfJob case final job?)
              ListenableBuilder(
                listenable: job,
                builder: (context, _) {
                  final running = job.state is PdfPreparing;
                  return SheetRow(
                    key: const ValueKey('ayah-surah-pdf'),
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'مشاركة السورة PDF',
                    subtitle: running ? 'يتم تجهيز ملف الآن' : null,
                    onTap: running ? null : _startPdf,
                  );
                },
              ),
          ],
          if (status != null) ...[
            const SizedBox(height: 10),
            StatusLine(key: const ValueKey('ayah-status'), message: status),
          ],
        ],
      ),
    );
  }

  /// The bookmark row of the ayah and, right after it, its note row (feature 013, contracts/ui.md §1), in the state the
  /// reader holds now.
  List<Widget> _bookmarkRows(AyahBookmarkPort port) {
    final state = port.state(widget.ref);
    final note = state.note?.trim() ?? '';
    return [
      SheetRow(
        key: const ValueKey('ayah-bookmark'),
        icon: state.bookmarked
            ? Icons.bookmark_remove_outlined
            : Icons.bookmark_add_outlined,
        label: state.bookmarked
            ? kAyahBookmarkRemoveLabel
            : kAyahBookmarkAddLabel,
        semanticsValue: state.bookmarked ? kAyahStateOn : kAyahStateOff,
        onTap: () => _toggleBookmark(port),
      ),
      SheetRow(
        key: const ValueKey('ayah-note'),
        icon: Icons.edit_note,
        label: kAyahNoteLabel,
        subtitle: note.isEmpty ? null : note,
        subtitleMaxLines: 1,
        semanticsValue: note.isEmpty ? kAyahNoteNone : kAyahNoteHas,
        onTap: () => _editNote(port),
      ),
      if (note.isNotEmpty)
        SheetRow(
          key: const ValueKey('ayah-note-show'),
          icon: Icons.sticky_note_2_outlined,
          label: kAyahNoteShowLabel,
          onTap: () => _showNote(port, note),
        ),
    ];
  }
}

/// One action of the menu: an ivory card at least 52 px tall, a button for screen readers.
class SheetRow extends StatelessWidget {
  const SheetRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.semanticsValue,
    this.subtitleMaxLines,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  /// How many lines the subtitle may take before it ends with an ellipsis (feature 013: the start of a note, one line);
  /// null, as before, for no limit.
  final int? subtitleMaxLines;

  /// The state a screen reader hears after the label (feature 013: «عليها علامة»), with the row's tap as its action;
  /// null, as before, for none.
  final String? semanticsValue;

  /// Null switches the row off.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final radius = BorderRadius.circular(look.rowRadius(14));
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: subtitle == null ? label : '$label، $subtitle',
        value: semanticsValue,
        // A row with a state (feature 013) is also a tap action for a screen reader; a row without one is as before.
        onTap: semanticsValue == null ? null : onTap,
        excludeSemantics: true,
        child: Material(
          color: look.cardFill,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: look.cardBorder),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: radius),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: enabled ? look.cardInk : look.cardDisabled,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: enabled ? look.cardInk : look.cardDisabled,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: subtitleMaxLines,
                              overflow: subtitleMaxLines == null
                                  ? null
                                  : TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: look.cardMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
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

/// A message under the rows (a failure); announced to screen readers.
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.cardFill,
          border: Border.all(color: look.cardBorderStrong),
          borderRadius: BorderRadius.circular(look.rowRadius(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: look.cardInk,
            ),
          ),
        ),
      ),
    );
  }
}
