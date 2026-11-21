import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../ayah/failures.dart';
import '../mushaf/mushaf_page_card.dart';
import '../mushaf/mushaf_repository.dart';
import '../mushaf/page_font_loader.dart';
import '../mushaf/page_look.dart';
import 'indexed_flate.dart';

/// The logical size every page picture and PDF page is drawn at: the Mushaf's own 1 : 1.5 proportion, so
/// the line height is limited by the width as in the reader.
const Size kPageLogicalSize = Size(400, 600);

/// The page picture is drawn at pixel ratio 5: 2000 x 3000 px, enough to stay sharp at 2x zoom on a
/// 1080-px-wide phone screen (spec SC-004).
const double kPicturePixelRatio = 5;

/// The PDF pages are drawn at pixel ratio 4: 1600 x 2400 px, about 220 dpi on the A4 sheet.
const double kPdfPixelRatio = 4;

/// Draws Mushaf pages offscreen for sharing.
abstract interface class PageRenderer {
  /// One page as a PNG in [look] (the app's look the owner chose; Emerald & Gold by default), without highlight or
  /// bars. Throws [ShareFailure] (`couldNotPrepare`) if it cannot be drawn.
  Future<Uint8List> picture(int page, {PageLook look = PageLook.screen});

  /// One page for the PDF: the same [look] as the picture, at 1600 x 2400 px, reduced to a 256-colour palette and
  /// deflated. Throws [ShareFailure] (`couldNotPrepare`) if it cannot be drawn.
  Future<IndexedPage> pdfPage(int page, {PageLook look = PageLook.screen});
}

/// Draws the real [MushafPageCard] in a short-lived overlay entry placed outside the visible screen, reads
/// it with `RepaintBoundary.toImage`, and removes the entry. It draws at a fixed logical size
/// ([kPageLogicalSize]) and with the system text scale switched off, so the result does not depend on the
/// phone's size or settings. Needs frames: while the app has none (in the background) it waits.
class OffscreenPageRenderer implements PageRenderer {
  OffscreenPageRenderer({
    required this.overlay,
    required this.mushaf,
    required this.fonts,
  });

  /// The overlay to draw in (the root navigator's).
  final OverlayState Function() overlay;
  final MushafRepository mushaf;
  final PageFontLoader fonts;

  @override
  Future<Uint8List> picture(int page, {PageLook look = PageLook.screen}) async {
    try {
      final image = await _paint(page, look, kPicturePixelRatio);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('the engine returned no PNG');
        return bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
      } finally {
        image.dispose();
      }
    } catch (error) {
      throw ShareFailure.fromError(error);
    }
  }

  @override
  Future<IndexedPage> pdfPage(
    int page, {
    PageLook look = PageLook.screen,
  }) async {
    try {
      final px = await renderRgba(page, look, kPdfPixelRatio);
      return await indexedFlatePage(
        width: px.width,
        height: px.height,
        rgba: px.rgba,
      );
    } catch (error) {
      throw ShareFailure.fromError(error);
    }
  }

  /// The raw RGBA pixels of [page] drawn in [look] at [pixelRatio] (the print pages are built from this).
  Future<({int width, int height, Uint8List rgba})> renderRgba(
    int page,
    PageLook look,
    double pixelRatio,
  ) async {
    try {
      final image = await _paint(page, look, pixelRatio);
      try {
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (bytes == null) throw StateError('the engine returned no pixels');
        return (
          width: image.width,
          height: image.height,
          rgba: bytes.buffer.asUint8List(
            bytes.offsetInBytes,
            bytes.lengthInBytes,
          ),
        );
      } finally {
        image.dispose();
      }
    } catch (error) {
      throw ShareFailure.fromError(error);
    }
  }

  Future<ui.Image> _paint(int page, PageLook look, double pixelRatio) async {
    final meta = await mushaf.loadMeta();
    final data = await mushaf.loadPage(page);
    final family = await fonts.ensure(page);
    final key = GlobalKey();
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        // Far to the left of the screen: laid out and painted, never seen.
        left: -kPageLogicalSize.width * 4,
        top: 0,
        width: kPageLogicalSize.width,
        height: kPageLogicalSize.height,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.noScaling),
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: look.background,
              // The overlay has no Material above it, and without one every Text falls back to the framework's
              // error style (a yellow double underline in debug builds); the reader draws the same page on a
              // Scaffold, so give the page the same footing.
              child: Material(
                type: MaterialType.transparency,
                child: MushafPageCard(
                  data: data,
                  meta: meta,
                  fontFamily: family,
                  look: look,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay().insert(entry);
    try {
      Object? lastError;
      // The entry needs a frame to be built, laid out and painted; a second one if the first was not enough.
      for (var attempt = 0; attempt < 4; attempt++) {
        await SchedulerBinding.instance.endOfFrame;
        final boundary =
            key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null || !boundary.hasSize) continue;
        try {
          return await boundary.toImage(pixelRatio: pixelRatio);
        } catch (error) {
          lastError = error;
        }
      }
      throw StateError('the page could not be drawn offscreen: $lastError');
    } finally {
      entry.remove();
    }
  }
}
