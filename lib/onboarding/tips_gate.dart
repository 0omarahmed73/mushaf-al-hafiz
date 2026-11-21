import 'package:material_ui/material_ui.dart';

import 'tips_dialog.dart';
import 'tips_store.dart';

/// Shows [child]; the first time the app is opened, once the first frame is drawn, it opens the first-run tips over it
/// (feature 008). It never shows them again once they were finished, skipped or left by back.
///
/// It is built to sit around the reader (`home: const TipsGate(child: ReaderScreen())`): the reader stays the first
/// screen (Constitution II) and keeps its own state under the popup. It needs a `Provider<WirdRepository>` above it, as
/// the app has; without one it only shows [child].
///
/// The stored flag is read once, in a post-frame callback, with a one-shot read (no drift stream, research D2). A read
/// that fails means no popup. [enabled] false makes the gate wait: while the splash (feature 009) is still on screen,
/// pass false, and the check runs once when it turns true (research D12).
class TipsGate extends StatefulWidget {
  const TipsGate({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// While false the gate only shows [child]; when it turns true the check runs, once.
  final bool enabled;

  @override
  State<TipsGate> createState() => _TipsGateState();
}

class _TipsGateState extends State<TipsGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(TipsGate old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !old.enabled) _schedule();
  }

  void _schedule() {
    if (!widget.enabled || _checked) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (!mounted || !widget.enabled || _checked) return;
    _checked = true;
    final store = TipsStore.maybeOf(context);
    if (store == null) return;
    final bool seen;
    try {
      seen = await store.seen();
    } catch (e, s) {
      debugPrint('first-run tips: could not read the flag: $e\n$s');
      return;
    }
    if (!mounted || seen) return;
    await showTips(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Marks the navigators that have the tips open now (research D11). A mark on the navigator, not a static flag: a navigator
/// that is thrown away (a test's teardown) takes its mark with it and never leaves the next one blocked.
final Expando<bool> _open = Expando<bool>('first-run tips are open');

/// Opens the first-run tips now, whatever the stored state, waits until they close, and stores that they were seen when
/// the reader finished or skipped them (a close without a result stores nothing, research D4). Never throws. A call while
/// the tips are already open on this navigator returns at once and opens nothing.
///
/// Called by [TipsGate] on the first launch, and by any screen that wants to show the tips again (a row in Settings).
Future<void> showTips(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (_open[navigator] ?? false) return;
  final store = TipsStore.maybeOf(context);
  _open[navigator] = true;
  TipsOutcome? outcome;
  try {
    outcome = await showDialog<TipsOutcome>(
      context: context,
      barrierDismissible: false,
      // The phone asked for reduced motion: the dialog is there, it does not fade or scale in.
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (_) => const TipsDialog(),
    );
  } catch (e, s) {
    debugPrint('first-run tips: could not show them: $e\n$s');
  } finally {
    _open[navigator] = false;
  }
  if (outcome == null || store == null) return;
  try {
    await store.markSeen();
  } catch (e, s) {
    debugPrint('first-run tips: could not store the flag: $e\n$s');
  }
}
