import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/pdf/pdf_writer.dart';
import 'package:mushaf/render/indexed_flate.dart';

import 'fake_renderer.dart';
import 'test_meta.dart';

/// A [PdfWriter] that writes nothing: counts the pages it was given and remembers finish and abort.
class NoDiskPdfWriter extends PdfWriter {
  NoDiskPdfWriter(super.file, {required super.title, required super.pageCount});

  int pages = 0;
  bool finished = false;
  bool aborted = false;

  @override
  Future<void> addPage(IndexedPage page) async => pages++;

  @override
  Future<void> finish() async => finished = true;

  @override
  Future<void> abort() async => aborted = true;
}

/// A [PdfJob] over [renderer] (a [FakePageRenderer]), the surahs of [pdfMeta] and no disk at all, for the widget
/// tests of the menu row, the progress strip and the reader.
PdfJob fakePdfJob(FakePageRenderer renderer, {TempShareFiles? files}) => PdfJob(
  renderer: renderer,
  files: files ?? MemoryShareFiles(),
  meta: pdfMeta(),
  writerFactory: (file, {required title, required pageCount}) =>
      NoDiskPdfWriter(file, title: title, pageCount: pageCount),
);
