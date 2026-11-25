import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'ayah/ayah_repository.dart';
import 'ayah/share_service.dart';
import 'backup/backup.dart';
import 'backup/backup_files.dart';
import 'backup/backup_service.dart';
import 'large_ayah/large_ayah_settings.dart';
import 'look/look_settings.dart';
import 'motion/frame_trace.dart';
import 'mushaf/mushaf_repository.dart';
import 'pdf/pdf_job.dart';
import 'mushaf/page_font_loader.dart';
import 'mushaf/reader_screen.dart';
import 'onboarding/tips_gate.dart';
import 'render/page_renderer.dart';
import 'reminders/background_refresh.dart';
import 'reminders/reminder_scheduler.dart';
import 'reminders/reminder_service.dart';
import 'search/search_service.dart';
import 'settings/ayah_tint_settings.dart';
import 'settings/text_size_settings.dart';
import 'splash/app_when_ready.dart';
import 'splash/splash_gate.dart';
import 'wirds/db.dart';
import 'wirds/wird_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Logs the frame times when the build asks for it (--dart-define=FRAME_TRACE=true); nothing at all otherwise (feature 010).
  FrameTrace.install();
  // The splash (feature 009) is drawn first and the app loads behind it, so the first frame no longer waits for the database,
  // the reminders and the saved settings, and the splash stays until they are ready.
  final app = _bootApp();
  runApp(
    SplashGate(
      ready: app,
      // The first-run tips (feature 008) wait for the splash to be gone, then open once over the reader.
      onFinished: () => _splashGone.value = true,
      child: AppWhenReady(app),
    ),
  );
}

/// True once the splash has handed over to the app; the tips gate waits for it.
final ValueNotifier<bool> _splashGone = ValueNotifier<bool>(false);

/// Everything the app needs before its first screen, then the app itself.
Future<MushafApp> _bootApp() async {
  final database = AppDatabase.open();
  final wirdRepository = WirdRepository(database);
  await wirdRepository.ensureDefaults();
  final reminders = await _startReminders(wirdRepository);
  // Pictures and PDFs shared earlier are no longer needed once the app starts again.
  try {
    await TempShareFiles().clean();
  } catch (e) {
    debugPrint('could not clean the share folder: $e');
  }
  final navigatorKey = GlobalKey<NavigatorState>();
  final mushafRepository = MushafRepository(rootBundle);
  final pageRenderer = OffscreenPageRenderer(
    overlay: () => navigatorKey.currentState!.overlay!,
    mushaf: mushafRepository,
    fonts: PageFontLoader(),
  );
  final tempShareFiles = TempShareFiles();
  // The chosen text size is read before the first frame so the reader never shows a wrong size first.
  final textSize = TextSizeSettings(wirdRepository);
  await textSize.load();
  // The chosen look is read before the first frame too, so the app never shows the other look first.
  final appLook = AppLookSettings(wirdRepository);
  await appLook.load();
  // The tint switch too, so the first frame of the reader already tints, or does not (feature 013).
  final ayahTint = AyahTintSettings(wirdRepository);
  await ayahTint.load();
  // The large-ayah view too: when it was left on, the app opens on it (feature 015, constitution 2.2.0 Principle II).
  final largeAyah = LargeAyahSettings(wirdRepository, meta: await mushafRepository.loadMeta());
  await largeAyah.load();
  return MushafApp(
    // The reader stays the first screen; the tips open over it once, after the splash (feature 008).
    home: ValueListenableBuilder<bool>(
      valueListenable: _splashGone,
      child: const ReaderScreen(),
      builder: (context, gone, reader) =>
          TipsGate(enabled: gone, child: reader!),
    ),
    wirdRepository: wirdRepository,
    mushafRepository: mushafRepository,
    reminders: reminders,
    ayahRepository: AyahRepository(rootBundle),
    shareService: PlatformShareService(),
    tempShareFiles: tempShareFiles,
    navigatorKey: navigatorKey,
    pageRenderer: pageRenderer,
    textSize: textSize,
    ayahTint: ayahTint,
    appLook: appLook,
    largeAyah: largeAyah,
    // Reads nothing now: the text of the ayat is read and folded when the search is first opened (feature 011, FR-022).
    searchService: SearchService(
      bundle: rootBundle,
      meta: mushafRepository.loadMeta,
    ),
    pdfJob: PdfJob(
      renderer: pageRenderer,
      files: tempShareFiles,
      meta: await mushafRepository.loadMeta(),
    ),
    backup: Backup(
      service: BackupService(database, meta: await mushafRepository.loadMeta()),
      files: PlatformBackupFiles(),
    ),
  );
}

/// Starts notifications. If anything here fails the Mushaf still opens, just without reminders.
Future<Reminders?> _startReminders(WirdRepository repo) async {
  try {
    final taps = NotificationTaps();
    final service = LocalNotificationService();
    await service.init(onTap: taps.add);
    final scheduler = ReminderScheduler(repo, service)..start();
    await registerBackgroundRefresh();
    // Ask for the notification permission once; Settings has a button for later.
    if (!await repo.notificationPermissionAsked()) {
      await repo.setNotificationPermissionAsked();
      if (await service.requestPermission()) scheduler.refresh(force: true);
    }
    return Reminders(service: service, scheduler: scheduler, taps: taps);
  } catch (e, s) {
    debugPrint('reminders could not start: $e\n$s');
    return null;
  }
}
