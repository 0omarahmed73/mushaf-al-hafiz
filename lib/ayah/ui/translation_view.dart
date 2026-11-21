import 'package:material_ui/material_ui.dart';

import '../ayah_ref.dart';
import '../ayah_repository.dart';
import 'reading_text.dart';
import 'sheet_detail.dart';

/// The English translation (Saheeh International) of one ayah, inside the ayah sheet: laid out left to
/// right in its own panel, labelled as a human work (spec FR-010, FR-012).
class TranslationView extends StatefulWidget {
  const TranslationView({
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

  /// Called with the English text when the share button is pressed.
  final void Function(String text) onShare;
  final String? status;

  @override
  State<TranslationView> createState() => _TranslationViewState();
}

class _TranslationViewState extends State<TranslationView> {
  late final Future<String> _text = widget.repository.translation(widget.ref);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _text,
      builder: (context, snapshot) {
        final text = snapshot.data;
        return SheetDetail(
          title: 'الترجمة',
          source: 'Saheeh International',
          onBack: widget.onBack,
          onShare: text == null ? null : () => widget.onShare(text),
          shareKey: const ValueKey('translation-share'),
          status: widget.status,
          child: _body(snapshot, text),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<String> snapshot, String? text) {
    if (snapshot.hasError) return const Text(kLoadFailed);
    if (text == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: ReadingScope.of(context).english,
      ),
    );
  }
}
