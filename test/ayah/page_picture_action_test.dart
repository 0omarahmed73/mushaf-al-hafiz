import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/ayah/page_picture_action.dart';
import 'package:mushaf/ayah/share_service.dart';

import '../support/fake_renderer.dart';
import '../support/fake_share.dart';

void main() {
  late FakePageRenderer renderer;
  late MemoryShareFiles files;
  late FakeShareService share;
  late PagePictureAction action;

  setUp(() {
    renderer = FakePageRenderer();
    files = MemoryShareFiles();
    share = FakeShareService();
    action = PagePictureAction(renderer: renderer, files: files, share: share);
  });

  test(
    'renders the page, writes «مصحف - صفحة 293.png» and shares it as image/png',
    () async {
      final outcome = await action.run(293);
      expect(outcome, ShareOutcome.shared);
      expect(renderer.pictured, [293]);
      expect(files.written.keys, ['/tmp/share/مصحف - صفحة 293.png']);
      expect(files.written.values.single, renderer.bytes);
      final shared = share.files.single;
      expect(
        (shared.path, shared.fileName, shared.mimeType),
        ('/tmp/share/مصحف - صفحة 293.png', 'مصحف - صفحة 293.png', 'image/png'),
      );
    },
  );

  test('a dismissed share sheet is not an error', () async {
    share.outcome = ShareOutcome.dismissed;
    expect(await action.run(1), ShareOutcome.dismissed);
  });

  test(
    'says it is slow only when rendering takes over half a second',
    () async {
      var slow = 0;
      await action.run(1, onSlow: () => slow++);
      expect(slow, 0);
      renderer.delay = const Duration(milliseconds: 650);
      await action.run(2, onSlow: () => slow++);
      expect(slow, 1);
    },
  );

  test('a render failure is ShareFailure(couldNotPrepare) and nothing is written or shared', () async {
    renderer.failure = const ShareFailure(ShareFailureKind.couldNotPrepare);
    await expectLater(
      action.run(293),
      throwsA(
        isA<ShareFailure>().having(
          (f) => f.kind,
          'kind',
          ShareFailureKind.couldNotPrepare,
        ),
      ),
    );
    expect(files.written, isEmpty);
    expect(share.files, isEmpty);
  });

  test('an unexpected render error is also couldNotPrepare', () async {
    renderer.failure = StateError('boom');
    await expectLater(
      action.run(293),
      throwsA(
        isA<ShareFailure>().having(
          (f) => f.kind,
          'kind',
          ShareFailureKind.couldNotPrepare,
        ),
      ),
    );
  });

  test('no room to write the file is ShareFailure(noSpace)', () async {
    files.diskFull = true;
    await expectLater(
      action.run(293),
      throwsA(
        isA<ShareFailure>().having(
          (f) => f.kind,
          'kind',
          ShareFailureKind.noSpace,
        ),
      ),
    );
    expect(share.files, isEmpty);
  });

  test('a failing share sheet is ShareFailure(couldNotShare)', () async {
    share.failure = const ShareFailure(ShareFailureKind.couldNotShare);
    await expectLater(
      action.run(293),
      throwsA(
        isA<ShareFailure>().having(
          (f) => f.kind,
          'kind',
          ShareFailureKind.couldNotShare,
        ),
      ),
    );
  });

  test('with a real temp folder the PNG lands in <temp>/share under its Arabic name', () async {
    final base = Directory.systemTemp.createTempSync('picture_action_');
    addTearDown(() => base.deleteSync(recursive: true));
    final real = PagePictureAction(
      renderer: renderer,
      files: TempShareFiles(baseDir: () async => base),
      share: share,
    );
    await real.run(604);
    final written = File('${base.path}/share/مصحف - صفحة 604.png');
    expect(await written.readAsBytes(), renderer.bytes);
  });
}
