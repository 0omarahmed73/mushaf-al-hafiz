import 'package:material_ui/material_ui.dart';

import '../ayah_ref.dart';
import '../ayah_repository.dart';
import '../../theme.dart';
import '../models.dart';
import 'reading_text.dart';
import 'sheet_detail.dart';

/// «معاني الكلمات»: the difficult words of one ayah with their meanings, each labelled with the book it
/// comes from, or a clear line when the ayah has none (spec FR-011, FR-012).
class MeaningsView extends StatefulWidget {
  const MeaningsView({
    super.key,
    required this.ref,
    required this.repository,
    required this.onBack,
  });

  final AyahRef ref;
  final AyahRepository repository;
  final VoidCallback onBack;

  @override
  State<MeaningsView> createState() => _MeaningsViewState();
}

class _MeaningsViewState extends State<MeaningsView> {
  late final Future<(List<GharibEntry>, List<Source>)> _data = _load();

  Future<(List<GharibEntry>, List<Source>)> _load() async {
    final entries = await widget.repository.gharib(widget.ref);
    final sources = await widget.repository.sources();
    return (entries, sources);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<GharibEntry>, List<Source>)>(
      future: _data,
      builder: (context, snapshot) {
        return SheetDetail(
          title: 'معاني الكلمات',
          onBack: widget.onBack,
          child: _body(snapshot),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<(List<GharibEntry>, List<Source>)> snapshot) {
    if (snapshot.hasError) return const Text(kLoadFailed);
    final data = snapshot.data;
    if (data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final (entries, sources) = data;
    if (entries.isEmpty) {
      return Text(
        'لا توجد كلمات غريبة في هذه الآية',
        style: ReadingScope.of(context).meaningText,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) Divider(height: 24, color: context.look.cardDivider),
          _Entry(
            entry: entries[i],
            source: widget.repository.sourceOfBook(sources, entries[i].book),
          ),
        ],
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry, required this.source});

  final GharibEntry entry;
  final Source? source;

  @override
  Widget build(BuildContext context) {
    final label = source == null
        ? null
        : '${source!.author} · ${source!.title}';
    final styles = ReadingScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.word, style: styles.meaningWord),
        const SizedBox(height: 4),
        Text(entry.meaning, style: styles.meaningText),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(label, style: styles.source),
        ],
      ],
    );
  }
}
