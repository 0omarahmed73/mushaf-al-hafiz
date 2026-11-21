// The surah PDF in the look in force when the job starts (spec FR-011, SC-007; research D4): the look reaches every
// page, the sheet behind the pages is the look's background, and changing the app's look afterwards does not touch a
// job that is running. Emerald & Gold is as before.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/theme.dart';

import '../support/fake_renderer.dart';
import '../support/test_meta.dart';

void main() {
  late Directory dir;
  late FakePageRenderer renderer;
  late PdfJob job;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pdf-look');
    renderer = FakePageRenderer();
    job = PdfJob(
      renderer: renderer,
      files: TempShareFiles(baseDir: () async => dir),
      meta: pdfMeta(),
    );
  });

  tearDown(() async {
    job.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<void> untilSettled() async {
    for (var i = 0; i < 400 && job.state is PdfPreparing; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// The colour the sheet of the finished PDF is filled with, read from its content stream.
  Color sheetColor() {
    final ready = job.state as PdfReady;
    final text = latin1.decode(File(ready.path).readAsBytesSync());
    final m = RegExp(r'q ([0-9.]+) ([0-9.]+) ([0-9.]+) rg 0 0 ')
        .firstMatch(text);
    expect(m, isNotNull, reason: 'the page has a filled sheet');
    return Color.from(
      alpha: 1,
      red: double.parse(m!.group(1)!),
      green: double.parse(m.group(2)!),
      blue: double.parse(m.group(3)!),
    );
  }

  bool near(Color a, Color b) =>
      (a.r - b.r).abs() < 0.001 &&
      (a.g - b.g).abs() < 0.001 &&
      (a.b - b.b).abs() < 0.001;

  test('a job started in Night draws every page in Night and fills the sheet with the Night background', () async {
    expect(job.start(2, look: PageLook.night), isTrue);
    await untilSettled();
    expect(job.state, isA<PdfReady>());
    expect(renderer.pdfLooks, hasLength(48));
    expect(
      renderer.pdfLooks.every((l) => identical(l, PageLook.night)),
      isTrue,
    );
    expect(near(sheetColor(), PageLook.night.background), isTrue);
  });

  test('without a look the job is the one it always was: Emerald pages on the green sheet', () async {
    expect(job.start(3), isTrue);
    await untilSettled();
    expect(
      renderer.pdfLooks.every((l) => identical(l, PageLook.screen)),
      isTrue,
    );
    expect(near(sheetColor(), AppColors.green), isTrue);
  });

  test('a look change while the job runs does not change the job', () async {
    final gate = Completer<void>();
    renderer.gate = gate.future;
    var current =
        PageLook.night; // what the app's setting says when the job starts
    expect(job.start(2, look: current), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    current =
        PageLook.screen; // the owner switches the look in Settings meanwhile
    renderer.gate = null;
    gate.complete();
    await untilSettled();
    expect(job.state, isA<PdfReady>());
    expect(renderer.pdfLooks, hasLength(48));
    expect(
      renderer.pdfLooks.every((l) => identical(l, PageLook.night)),
      isTrue,
      reason: 'all 48 pages are Night although the setting is now Emerald',
    );
    expect(near(sheetColor(), PageLook.night.background), isTrue);
    expect(current, same(PageLook.screen));
  });

  test('the next job takes the look in force then', () async {
    expect(job.start(3, look: PageLook.night), isTrue);
    await untilSettled();
    expect(job.start(3), isTrue);
    await untilSettled();
    expect(renderer.pdfLooks.map((l) => identical(l, PageLook.night)), [
      true,
      false,
    ]);
  });
}
