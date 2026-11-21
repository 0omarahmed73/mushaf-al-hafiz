import 'package:material_ui/material_ui.dart';

import '../ayah/ui/reading_text.dart';
import '../theme.dart';
import 'dua_strings.dart';
import 'dua_text.dart';

/// «دعاء ختم القرآن»: the app's one supplication, shown after the last page of the Mushaf (spec FR-009 to FR-015).
///
/// A full-screen route opened by the reader. It pops `true` for «آمين» (the reader then shows page 1) and with no
/// result for the back arrow and the system back (the reader stays on page 604). It writes nothing and stores
/// nothing (FR-008). The dua is set in the interface font at the owner's reading size, in a panel under a line
/// that says it is not part of the Quran text; «آمين» is the last item of the scrolling content, so it is
/// reachable at every screen size and text size (FR-011).
class KhatmDuaScreen extends StatefulWidget {
  const KhatmDuaScreen({super.key});

  @override
  State<KhatmDuaScreen> createState() => _KhatmDuaScreenState();
}

class _KhatmDuaScreenState extends State<KhatmDuaScreen> {
  late final Future<DuaText> _dua = DuaText.load(
    DefaultAssetBundle.of(context),
  );

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Scaffold(
      appBar: AppBar(title: const Text(kDuaTitle)),
      body: SafeArea(
        child: ReadingScope(
          child: Scrollbar(
            child: SingleChildScrollView(
              key: const ValueKey('khatm-scroll'),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text(
                      kDuaNote,
                      key: const ValueKey('khatm-note'),
                      style: TextStyle(fontSize: 12, color: look.textSecondary),
                    ),
                  ),
                  FutureBuilder<DuaText>(
                    future: _dua,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const _Unavailable();
                      final dua = snapshot.data;
                      if (dua == null) return const _Loading();
                      return _Panel(dua: dua);
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const ValueKey('khatm-amen'),
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          look.buttonRadius(14),
                        ),
                      ),
                    ),
                    child: const Text(kDuaAmen),
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

/// The dua in the card colours of the chosen look.
class _Panel extends StatelessWidget {
  const _Panel({required this.dua});

  final DuaText dua;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final style = ReadingScope.of(context).arabic;
    return DecoratedBox(
      key: const ValueKey('khatm-panel'),
      decoration: BoxDecoration(
        color: look.cardFill,
        border: Border.all(color: look.cardBorderStrong),
        borderRadius: BorderRadius.circular(look.rowRadius(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: look.cardInk),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < dua.paragraphs.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == dua.paragraphs.length - 1 ? 0 : 14,
                  ),
                  child: Text(
                    dua.paragraphs[i],
                    key: ValueKey('khatm-text-$i'),
                    style: style,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown while the text is read: it is a few hundred bytes, so this is a blink.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: Center(child: CircularProgressIndicator()),
  );
}

/// The text file could not be read (spec FR-019): a short message in place of the dua.
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: look.cardFill,
        border: Border.all(color: look.cardBorderStrong),
        borderRadius: BorderRadius.circular(look.rowRadius(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          kDuaUnavailable,
          key: const ValueKey('khatm-unavailable'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: look.cardInk,
          ),
        ),
      ),
    );
  }
}
