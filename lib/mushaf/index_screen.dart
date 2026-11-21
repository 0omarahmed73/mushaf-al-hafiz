import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../digits.dart';
import '../search/search_screen.dart';
import '../search/search_service.dart';
import '../search/search_strings.dart';
import 'models.dart';
import 'mushaf_repository.dart';

/// Index with three tabs: surahs, juz and a page-number field. Pops with the chosen page (1..604) or, from the search
/// screen (feature 011), with whatever a search result is: the first page of a surah or an `AyahTarget`.
class IndexScreen extends StatelessWidget {
  const IndexScreen({super.key});

  /// Opens the search over the index; a chosen result closes the index too, with the result unchanged. Back from the
  /// search (no result) leaves the index as it was.
  Future<void> _openSearch(BuildContext context) async {
    final navigator = Navigator.of(context);
    final result = await navigator.push<Object>(
      MaterialPageRoute<Object>(builder: (_) => const SearchScreen()),
    );
    if (result != null && context.mounted) navigator.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    // The icon is there only when the app provides the search (every earlier test provides none: the index is unchanged).
    final hasSearch = context.read<SearchService?>() != null;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الفهرس'),
          actions: hasSearch
              ? [
                  IconButton(
                    key: const ValueKey('open-search'),
                    tooltip: kSearchLabel,
                    icon: const Icon(Icons.search),
                    onPressed: () => _openSearch(context),
                  ),
                ]
              : null,
          bottom: const TabBar(tabs: [Tab(text: 'السور'), Tab(text: 'الأجزاء'), Tab(text: 'صفحة')]),
        ),
        body: FutureBuilder<MushafMeta>(
          future: context.read<MushafRepository>().loadMeta(),
          builder: (context, snapshot) {
            final meta = snapshot.data;
            if (meta == null) return const Center(child: CircularProgressIndicator());
            return TabBarView(children: [
              _SurahList(meta: meta),
              _JuzList(meta: meta),
              const _PageField(),
            ]);
          },
        ),
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.meta});

  final MushafMeta meta;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey('surah-list'),
      itemCount: meta.surahs.length,
      itemBuilder: (context, i) {
        final surah = meta.surahs[i];
        return ListTile(
          leading: Text('${surah.number}'),
          title: Text(surah.name),
          trailing: Text('ص ${surah.startPage}'),
          onTap: () => Navigator.of(context).pop(surah.startPage),
        );
      },
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList({required this.meta});

  final MushafMeta meta;

  int _firstPageOf(int juz) {
    for (var p = 1; p <= MushafMeta.pageCount; p++) {
      if (meta.juzOf(p) == juz) return p;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey('juz-list'),
      itemCount: 30,
      itemBuilder: (context, i) {
        final page = _firstPageOf(i + 1);
        return ListTile(
          title: Text('الجزء ${i + 1}'),
          trailing: Text('ص $page'),
          onTap: () => Navigator.of(context).pop(page),
        );
      },
    );
  }
}

class _PageField extends StatefulWidget {
  const _PageField();

  @override
  State<_PageField> createState() => _PageFieldState();
}

class _PageFieldState extends State<_PageField> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final page = int.tryParse(_controller.text.trim());
    if (page == null || page < 1 || page > 604) {
      setState(() => _error = 'أدخل رقماً من 1 إلى 604');
      return;
    }
    Navigator.of(context).pop(page);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('page-field'),
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [const DigitsOnlyFormatter()],
            decoration: InputDecoration(labelText: 'رقم الصفحة من 1 إلى 604', errorText: _error),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(key: const ValueKey('page-go'), onPressed: _submit, child: const Text('اذهب')),
        ],
      ),
    );
  }
}
