import 'package:material_ui/material_ui.dart';

import '../../theme.dart';
import 'ayah_sheet.dart' show StatusLine;
import 'reading_text.dart';

/// The wording shown under the title of every view of human work (tafsir, translation, word meanings), so a
/// human explanation is never mistaken for the words of the Quran (spec FR-012).
const String kHumanWorkNote = 'شرح بشري وليس من نص القرآن';

/// «تعذّر تحميل هذا القسم»: shown inside a view whose data could not be read (a build bug, not expected).
const String kLoadFailed = 'تعذّر تحميل هذا القسم';

/// A view inside the ayah sheet: a back arrow, a title, optional source and note lines, an optional share
/// button, and an ivory panel that scrolls. The Quran words are never repeated inside the panel.
class SheetDetail extends StatelessWidget {
  const SheetDetail({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.source,
    this.onShare,
    this.shareKey,
    this.status,
  });

  final String title;

  /// A line under the title naming the source when the title does not (for example «Saheeh International»).
  final String? source;
  final VoidCallback onBack;

  /// Null hides the share button.
  final VoidCallback? onShare;
  final ValueKey<String>? shareKey;

  /// A failure message shown under the panel.
  final String? status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('ayah-back'),
                tooltip: 'رجوع',
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: look.accent),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: headingStyle(20, look.heading)),
                    if (source != null)
                      Text(
                        source!,
                        style: TextStyle(fontSize: 13, color: look.text),
                      ),
                    Text(
                      kHumanWorkNote,
                      style: TextStyle(fontSize: 12, color: look.textSecondary),
                    ),
                  ],
                ),
              ),
              if (onShare != null)
                IconButton(
                  key: shareKey,
                  tooltip: 'مشاركة',
                  onPressed: onShare,
                  icon: Icon(Icons.share_outlined, color: look.accent),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: look.cardFill,
                border: Border.all(color: look.cardBorderStrong),
                borderRadius: BorderRadius.circular(look.rowRadius(14)),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  key: const ValueKey('ayah-detail-body'),
                  padding: const EdgeInsets.all(16),
                  // The panel is the reading text: it follows the owner's size (feature 003); the header above
                  // and the rows of the menu do not.
                  child: ReadingScope(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: look.cardInk),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 10),
            StatusLine(key: const ValueKey('ayah-status'), message: status!),
          ],
        ],
      ),
    );
  }
}

/// A paragraph-by-paragraph body for Arabic text (paragraphs are separated by a blank line).
class Paragraphs extends StatelessWidget {
  const Paragraphs(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final paragraphs = text.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(p, style: ReadingScope.of(context).arabic),
          ),
      ],
    );
  }
}
