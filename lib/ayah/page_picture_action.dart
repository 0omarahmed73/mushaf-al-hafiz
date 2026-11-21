import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

import 'dart:ui' show VoidCallback;

import '../mushaf/page_look.dart';
import '../render/page_renderer.dart';
import 'failures.dart';
import 'file_names.dart';
import 'share_service.dart';

/// «مشاركة الصفحة كصورة»: draws a page, writes it to the share folder under its Arabic name and hands it to
/// the share sheet (spec FR-014, FR-018). It takes only a page number: nothing of the user's wirds,
/// positions or bookmarks can end up in the picture, and the reading position is never touched.
class PagePictureAction {
  PagePictureAction({
    required this.renderer,
    required this.files,
    required this.share,
    this.look = PageLook.screen,
  });

  final PageRenderer renderer;
  final TempShareFiles files;
  final ShareService share;

  /// The look the picture is drawn in: the owner's chosen look when the menu was opened (spec 004 FR-010).
  final PageLook look;

  /// How long a render may take before the user is told it is being prepared.
  static const Duration slowAfter = Duration(milliseconds: 500);

  /// Built with `--dart-define=AYAH_MENU_TRACE=true`, each picture logs how long it took (spec SC-004).
  static const bool _trace = bool.fromEnvironment('AYAH_MENU_TRACE');

  /// Throws [ShareFailure] (`couldNotPrepare`, `noSpace` or `couldNotShare`); a dismissed share sheet is
  /// [ShareOutcome.dismissed], not an error. [onSlow] is called once if preparing takes over
  /// [slowAfter].
  Future<ShareOutcome> run(int page, {VoidCallback? onSlow}) async {
    final timer = onSlow == null ? null : Timer(slowAfter, onSlow);
    final String name = FileNames.page(page);
    final String path;
    final stopwatch = Stopwatch()..start();
    try {
      final bytes = await renderer.picture(page, look: look);
      final renderMs = stopwatch.elapsedMilliseconds;
      final file = await files.create(name);
      await file.writeAsBytes(bytes, flush: true);
      path = file.path;
      if (_trace) {
        debugPrint(
          'PICTURE page=$page render_ms=$renderMs total_ms=${stopwatch.elapsedMilliseconds} bytes=${bytes.length}',
        );
        await _keepCopyForInspection(page, bytes);
      }
    } catch (error) {
      throw ShareFailure.fromError(error);
    } finally {
      timer?.cancel();
    }
    return share.shareFile(path: path, fileName: name, mimeType: 'image/png');
  }

  /// Trace builds only: a copy of the picture in the app's external files folder, so it can be fetched with
  /// `adb pull` and compared with the page on the screen (the share folder is private).
  Future<void> _keepCopyForInspection(int page, List<int> bytes) async {
    try {
      final folder = await getExternalStorageDirectory();
      if (folder == null) return;
      final file = File('${folder.path}/picture-$page.png');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('PICTURE copy=${file.path}');
    } catch (error) {
      debugPrint('PICTURE copy failed: $error');
    }
  }
}
