import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'ayah/ayah_repository.dart';
import 'ayah/share_service.dart';
import 'backup/backup.dart';
import 'large_ayah/large_ayah_settings.dart';
import 'look/look_settings.dart';
import 'motion/look_fade.dart';
import 'pdf/pdf_job.dart';
import 'render/page_renderer.dart';
import 'mushaf/mushaf_repository.dart';
import 'mushaf/reader_screen.dart';
import 'reminders/reminder_scheduler.dart';
import 'search/search_service.dart';
import 'settings/ayah_tint_settings.dart';
import 'settings/text_size_settings.dart';
import 'theme.dart';
import 'wirds/wird_repository.dart';

/// Root widget: Arabic, right-to-left, one emerald-and-gold theme.
class MushafApp extends StatelessWidget {
  const MushafApp({
    super.key,
    required this.wirdRepository,
    required this.mushafRepository,
    this.reminders,
    this.backup,
    this.ayahRepository,
    this.shareService,
    this.pageRenderer,
    this.tempShareFiles,
    this.pdfJob,
    this.textSize,
    this.ayahTint,
    this.appLook,
    this.largeAyah,
    this.searchService,
    this.navigatorKey,
    this.home,
  });

  final WirdRepository wirdRepository;
  final MushafRepository mushafRepository;

  /// Notifications; null in tests that do not need them.
  final Reminders? reminders;

  /// Export and import of the user's data; null in tests that do not need them.
  final Backup? backup;

  /// The Quran words, tafsir, translation and word meanings of an ayah, and the share sheet; null in
  /// tests that do not need the ayah menu.
  final AyahRepository? ayahRepository;
  final ShareService? shareService;

  /// Draws a page as a picture and the folder it is written to before sharing; null in tests that do not
  /// need «مشاركة الصفحة كصورة».
  final PageRenderer? pageRenderer;
  final TempShareFiles? tempShareFiles;

  /// Prepares the PDF of a surah in the background; its progress strip is shown by the reader. Null in
  /// tests that do not need «مشاركة السورة PDF».
  final PdfJob? pdfJob;

  /// The size the owner chose for the reading texts and the Mushaf page; null (tests that do not care) means
  /// 100%.
  final TextSizeSettings? textSize;

  /// The Settings switch of the tint behind bookmarked ayat (feature 013); null (tests that do not care) means on, and
  /// Settings shows no switch.
  final AyahTintSettings? ayahTint;

  /// The look the owner chose, Emerald & Gold or Night Reader; null (tests that do not care) means Emerald & Gold.
  final AppLookSettings? appLook;

  /// The large-ayah view's settings (feature 015); none means the view is off.
  final LargeAyahSettings? largeAyah;

  /// The search of surah names and ayat (feature 011): one per run, created at launch and reading nothing until the search is
  /// opened. Null (every test that does not need it) means the index shows no search icon.
  final SearchService? searchService;

  /// The root navigator's key; the page renderer draws in its overlay.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The first screen; the reader unless a test supplies another.
  final Widget? home;

  static const String title = 'مصحف الحافظ';

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WirdRepository>.value(value: wirdRepository),
        Provider<MushafRepository>.value(value: mushafRepository),
        Provider<Reminders?>.value(value: reminders),
        Provider<Backup?>.value(value: backup),
        Provider<AyahRepository?>.value(value: ayahRepository),
        Provider<ShareService?>.value(value: shareService),
        Provider<PageRenderer?>.value(value: pageRenderer),
        Provider<TempShareFiles?>.value(value: tempShareFiles),
        ListenableProvider<PdfJob?>.value(value: pdfJob),
        ListenableProvider<TextSizeSettings?>.value(value: textSize),
        ListenableProvider<AyahTintSettings?>.value(value: ayahTint),
        ListenableProvider<AppLookSettings?>.value(value: appLook),
        ListenableProvider<LargeAyahSettings?>.value(value: largeAyah),
        // A ChangeNotifier, so the Listenable flavour (a plain Provider refuses one in debug); a screen only reads it. Only
        // when there is one: a screen reads null either way, and a service provided above the app is not hidden by a null.
        if (searchService != null)
          ListenableProvider<SearchService?>.value(value: searchService),
      ],
      // The theme is built from the chosen look, so the first frame is already in it and a change applies to every
      // open screen at once (spec FR-003, FR-015). It is switched instantly: halfway between two looks there is
      // nothing sensible to draw.
      child: ListenableBuilder(
        listenable: appLook ?? _never,
        builder: (context, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: title,
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildAppTheme(look: appLook?.look ?? AppLook.emerald),
          themeAnimationDuration: Duration.zero,
          themeMode: ThemeMode.light,
          // Above the navigator, so a look change fades over any open screen (feature 010, FR-012).
          builder: (context, child) => LookFadeHost(child: child!),
          home: home ?? const ReaderScreen(),
        ),
      ),
    );
  }

  static final Listenable _never = Listenable.merge(const <Listenable>[]);
}
