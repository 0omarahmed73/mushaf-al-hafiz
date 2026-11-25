// The ayah sheet alone with a fake AyahBookmarkPort (feature 013): the sheet's bookmark and note rows without a reader.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_bookmark_port.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/render/page_renderer.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/ayah_bookmark_change.dart';
import 'package:provider/provider.dart';

import 'ayah_harness.dart' show viewFiles;
import 'fake_renderer.dart';
import 'fake_share.dart';
import 'map_bundle.dart';
import 'test_meta.dart';

/// A port whose state is what the test sets, answered synchronously, and whose every call is recorded.
class FakeAyahPort {
  FakeAyahPort({this.bookmarked = false, this.note});

  bool bookmarked;
  String? note;
  final List<AyahRef> toggles = [];
  final List<(AyahRef, String?)> saves = [];
  final List<AyahBookmarkChange> changes = [];

  /// What a save answers: a change by default, null (case d) when set, or [saveError] thrown.
  bool saveReturnsNull = false;
  Object? saveError;

  late final AyahBookmarkPort port = AyahBookmarkPort(
    state: (ref) => (bookmarked: bookmarked, note: note),
    toggle: (ref) async {
      toggles.add(ref);
      return AyahBookmarkChange(
        kind: bookmarked ? AyahChangeKind.removed : AyahChangeKind.added,
        ref: ref,
        page: 42,
        addedId: bookmarked ? null : 1,
      );
    },
    saveNote: (ref, text) async {
      saves.add((ref, text));
      final error = saveError;
      if (error != null) throw error;
      if (saveReturnsNull) return null;
      return AyahBookmarkChange(
        kind: bookmarked
            ? AyahChangeKind.noteReplaced
            : AyahChangeKind.createdWithNote,
        ref: ref,
        page: 42,
        addedId: bookmarked ? null : 1,
        before: bookmarked ? [(id: 1, note: note)] : const [],
      );
    },
    onChange: changes.add,
  );
}

/// The ayah sheet of [ref] (surah 2 of `testMeta`, over the small assets of ayah_harness.dart) opened by a button, with
/// [port] (no bookmark rows when null) and, when [withPicture], the «الصفحة والسورة» section's picture row.
class AyahSheetWithPort {
  AyahSheetWithPort({
    this.ref = const AyahRef(2, 6),
    this.port,
    this.withPicture = true,
    this.look,
    this.textSize,
  });

  final AyahRef ref;
  final FakeAyahPort? port;
  final bool withPicture;
  final AppLookSettings? look;
  final TextSizeSettings? textSize;
  final FakeShareService share = FakeShareService();
  final FakePageRenderer renderer = FakePageRenderer();
  final MemoryShareFiles files = MemoryShareFiles();
  int closed = 0;

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AyahRepository?>.value(
            value: AyahRepository(MapBundle(viewFiles())),
          ),
          Provider<ShareService?>.value(value: share),
          Provider<PageRenderer?>.value(value: withPicture ? renderer : null),
          Provider<TempShareFiles?>.value(value: withPicture ? files : null),
          ListenableProvider<AppLookSettings?>.value(value: look),
          ListenableProvider<TextSizeSettings?>.value(value: textSize),
        ],
        child: ListenableBuilder(
          listenable: look ?? Listenable.merge(const <Listenable>[]),
          builder: (context, _) => MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildAppTheme(look: look?.look ?? AppLook.emerald),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    key: const ValueKey('open'),
                    onPressed: () async {
                      await showAyahSheet(
                        context,
                        ref: ref,
                        meta: testMeta(),
                        page: 42,
                        bookmarks: port?.port,
                      );
                      closed++;
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Taps the button and lets the sheet slide in.
  Future<void> open(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('open')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }
}
