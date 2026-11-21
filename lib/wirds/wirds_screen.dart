import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../look/wird_marker.dart';
import '../theme.dart';
import 'today_panel.dart';
import 'wird_form_screen.dart';
import 'wird_repository.dart';

/// «أوراد»: today's summary, then every wird with its position, bookmarks and khatmas. Tapping a wird
/// makes it active and pops with its id so the reader can show it (spec FR-026).
class WirdsScreen extends StatefulWidget {
  const WirdsScreen({super.key});

  @override
  State<WirdsScreen> createState() => _WirdsScreenState();
}

class _WirdsScreenState extends State<WirdsScreen> {
  late final WirdRepository _repo = context.read<WirdRepository>();
  StreamSubscription<List<Wird>>? _wirdsSub;
  StreamSubscription<List<TodayEntry>>? _todaySub;
  List<Wird>? _wirds;
  Map<int, int> _bookmarks = const {};
  int? _activeId;
  List<TodayEntry> _today = const [];

  @override
  void initState() {
    super.initState();
    _wirdsSub = _repo.watchWirds().listen(_onWirds);
    _todaySub = _repo.watchTodayEntries().listen((e) {
      if (mounted) setState(() => _today = e);
    });
  }

  @override
  void dispose() {
    _wirdsSub?.cancel();
    _todaySub?.cancel();
    super.dispose();
  }

  Future<void> _onWirds(List<Wird> wirds) async {
    final counts = {
      for (final w in wirds) w.id: await _repo.bookmarkCount(w.id),
    };
    final active = (await _repo.activeWird())?.id;
    if (!mounted) return;
    setState(() {
      _wirds = wirds;
      _bookmarks = counts;
      _activeId = active;
    });
  }

  Future<void> _open(Wird wird) async {
    await _repo.setActive(wird.id);
    if (mounted) Navigator.of(context).pop(wird.id);
  }

  Future<void> _add() => Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => WirdFormScreen(colorIndex: _wirds?.length ?? 0),
    ),
  );

  Future<void> _edit(Wird wird) => Navigator.of(
    context,
  ).push<bool>(MaterialPageRoute(builder: (_) => WirdFormScreen(wird: wird)));

  Future<void> _confirmDelete(Wird wird) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الورد؟'),
        content: Text(
          'سيُحذف «${wird.name}» مع تقدمه، وتبقى علاماته علامات عامة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            key: const ValueKey('delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (yes == true) await _repo.delete(wird.id);
  }

  Future<void> _markDone(TodayEntry entry) =>
      _repo.markDone(entry.wird.id, DateTime.now());

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final wirds = _wirds;
    return Scaffold(
      appBar: AppBar(
        title: const Text('أوراد'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: IconButton(
              key: const ValueKey('wird-add-top'),
              tooltip: 'إضافة ورد',
              onPressed: _add,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                side: BorderSide(
                  color: look.controlBorder,
                  width: look.roundAddButton ? 1 : 1.5,
                ),
                shape: look.roundAddButton
                    ? const CircleBorder()
                    : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: wirds == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              children: [
                if (_today.isNotEmpty) ...[
                  const _SectionLabel('ملخص اليوم'),
                  TodayCard(entries: _today, onDone: _markDone),
                  const SizedBox(height: 22),
                ],
                const _SectionLabel('أورادي'),
                if (wirds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'لا توجد أوراد. أضف وردك الأول.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final w in wirds)
                  _WirdCard(
                    wird: w,
                    active: w.id == _activeId,
                    bookmarks: _bookmarks[w.id] ?? 0,
                    onOpen: () => _open(w),
                    onEdit: () => _edit(w),
                    onDelete: () => _confirmDelete(w),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: look.pillShapes
              ? OutlinedButton.icon(
                  key: const ValueKey('wird-add'),
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('ورد جديد'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: look.text,
                    side: BorderSide(color: look.controlBorder),
                    shape: const StadiumBorder(),
                  ),
                )
              : FilledButton.icon(
                  key: const ValueKey('wird-add'),
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('ورد جديد'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.look.textSecondary,
      ),
    ),
  );
}

class _WirdCard extends StatelessWidget {
  const _WirdCard({
    required this.wird,
    required this.active,
    required this.bookmarks,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Wird wird;
  final bool active;
  final int bookmarks;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final dot = Text('·', style: TextStyle(color: look.cardMuted));
    final muted = TextStyle(fontSize: 13, color: look.cardMuted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: look.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(look.cardRadius),
          side: BorderSide(
            color: active ? look.cardBorderActive : look.cardBorder,
            width: active ? look.strongBorderWidth : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('wird-${wird.id}'),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(look.cardRadius),
          ),
          onTap: onOpen,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: look.cardInk),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      WirdMarker(color: Color(wird.color)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          wird.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (active) const CardTag('النشط', filled: true),
                      PopupMenuButton<String>(
                        key: ValueKey('wird-menu-${wird.id}'),
                        tooltip: 'خيارات الورد',
                        icon: Icon(Icons.more_vert, color: look.cardInk),
                        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CardTag(wird.type.label),
                        Text('ص: ${wird.currentPage}', style: muted),
                        dot,
                        Text('علامات: $bookmarks', style: muted),
                        dot,
                        Text('ختمات: ${wird.khatmaCount}', style: muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
