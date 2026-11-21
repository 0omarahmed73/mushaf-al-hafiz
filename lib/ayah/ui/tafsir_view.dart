import 'package:material_ui/material_ui.dart';

import '../ayah_ref.dart';
import '../ayah_repository.dart';
import '../models.dart';
import 'reading_text.dart';
import 'sheet_detail.dart';

/// «تفسير السعدي» for one ayah, inside the ayah sheet. An entry that covers several ayahs says which ones;
/// an ayah the source has no commentary of its own for shows the nearest earlier entry with a note
/// (spec FR-009, FR-009a).
class TafsirView extends StatefulWidget {
  const TafsirView({
    super.key,
    required this.ref,
    required this.repository,
    required this.onBack,
    required this.onShare,
    this.status,
  });

  final AyahRef ref;
  final AyahRepository repository;
  final VoidCallback onBack;

  /// Called with the entry's text when the share button is pressed.
  final void Function(String text) onShare;
  final String? status;

  @override
  State<TafsirView> createState() => _TafsirViewState();
}

class _TafsirViewState extends State<TafsirView> {
  late final Future<TafsirResult> _result = widget.repository.tafsir(
    widget.ref,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TafsirResult>(
      future: _result,
      builder: (context, snapshot) {
        final result = snapshot.data;
        return SheetDetail(
          title: 'تفسير السعدي',
          onBack: widget.onBack,
          onShare: result == null
              ? null
              : () => widget.onShare(result.entry.text),
          shareKey: const ValueKey('tafsir-share'),
          status: widget.status,
          child: _body(snapshot, result),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<TafsirResult> snapshot, TafsirResult? result) {
    if (snapshot.hasError) return const Text(kLoadFailed);
    if (result == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final entry = result.entry;
    final String? line = result.inherited
        ? 'لا يوجد في هذا النص تعليق مستقل على هذه الآية، وهذا تفسير الآيات ${entry.covers}'
        : (entry.from == entry.to
              ? null
              : 'يشمل التفسير الآيات ${entry.covers}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (line != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(line, style: ReadingScope.of(context).note),
          ),
        Paragraphs(entry.text),
      ],
    );
  }
}
