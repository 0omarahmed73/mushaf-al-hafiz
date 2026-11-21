import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:share_plus/share_plus.dart';

import '../support/fake_share.dart';

void main() {
  group('ShareFailure', () {
    test('has one Arabic message per kind (contracts/ui.md)', () {
      expect(
        const ShareFailure(ShareFailureKind.noSpace).message,
        'لا توجد مساحة كافية على الهاتف لتجهيز الملف',
      );
      expect(
        const ShareFailure(ShareFailureKind.couldNotPrepare).message,
        'تعذّر تجهيز الملف',
      );
      expect(
        const ShareFailure(ShareFailureKind.couldNotShare).message,
        'تعذّرت المشاركة',
      );
    });

    test('a file system error with the no-space code is noSpace, any other is couldNotPrepare', () {
      const noSpace = FileSystemException(
        'write failed',
        '/x',
        OSError('No space left on device', 28),
      );
      const other = FileSystemException(
        'write failed',
        '/x',
        OSError('Permission denied', 13),
      );
      expect(ShareFailure.fromError(noSpace).kind, ShareFailureKind.noSpace);
      expect(
        ShareFailure.fromError(other).kind,
        ShareFailureKind.couldNotPrepare,
      );
      expect(
        ShareFailure.fromError(StateError('x')).kind,
        ShareFailureKind.couldNotPrepare,
      );
    });

    test('an error that already is a ShareFailure is kept as it is', () {
      const failure = ShareFailure(ShareFailureKind.couldNotShare);
      expect(identical(ShareFailure.fromError(failure), failure), isTrue);
    });
  });

  group('PlatformShareService', () {
    late List<ShareParams> given;
    late ShareResult result;
    late Object? error;
    late PlatformShareService service;

    setUp(() {
      given = [];
      result = const ShareResult('app', ShareResultStatus.success);
      error = null;
      service = PlatformShareService(
        share: (params) async {
          given.add(params);
          if (error != null) throw error!;
          return result;
        },
      );
    });

    test('shareText hands exactly the text to the share sheet', () async {
      expect(await service.shareText('نص'), ShareOutcome.shared);
      expect(given.single.text, 'نص');
      expect(given.single.files, isNull);
    });

    test('shareFile hands one file with its path, name and type', () async {
      final outcome = await service.shareFile(
        path: '/tmp/share/مصحف - صفحة 293.png',
        fileName: 'مصحف - صفحة 293.png',
        mimeType: 'image/png',
      );
      expect(outcome, ShareOutcome.shared);
      final file = given.single.files!.single;
      expect(file.path, '/tmp/share/مصحف - صفحة 293.png');
      expect(file.mimeType, 'image/png');
      expect(file.name, 'مصحف - صفحة 293.png');
      expect(given.single.text, isNull);
    });

    test(
      'a dismissed share sheet is the dismissed outcome, not an error',
      () async {
        result = const ShareResult('', ShareResultStatus.dismissed);
        expect(await service.shareText('x'), ShareOutcome.dismissed);
      },
    );

    test(
      'an unavailable result (the platform cannot say) counts as shared',
      () async {
        result = ShareResult.unavailable;
        expect(await service.shareText('x'), ShareOutcome.shared);
      },
    );

    test('a platform error becomes ShareFailure(couldNotShare)', () async {
      error = StateError('no activity');
      await expectLater(
        service.shareText('x'),
        throwsA(
          isA<ShareFailure>().having(
            (f) => f.kind,
            'kind',
            ShareFailureKind.couldNotShare,
          ),
        ),
      );
      await expectLater(
        service.shareFile(
          path: '/p',
          fileName: 'f',
          mimeType: 'application/pdf',
        ),
        throwsA(
          isA<ShareFailure>().having(
            (f) => f.kind,
            'kind',
            ShareFailureKind.couldNotShare,
          ),
        ),
      );
    });
  });

  group('TempShareFiles', () {
    late Directory base;
    late TempShareFiles files;

    setUp(() {
      base = Directory.systemTemp.createTempSync('share_test_');
      files = TempShareFiles(baseDir: () async => base);
      addTearDown(() {
        if (base.existsSync()) base.deleteSync(recursive: true);
      });
    });

    test('create gives a file named as asked inside <temp>/share and creates the folder', () async {
      final file = await files.create('سورة البقرة.pdf');
      expect(file.path, '${base.path}/share/سورة البقرة.pdf');
      await file.writeAsString('x');
      expect(File('${base.path}/share/سورة البقرة.pdf').existsSync(), isTrue);
    });

    test('create replaces an older file with the same name', () async {
      final first = await files.create('a.png');
      await first.writeAsString('old');
      final second = await files.create('a.png');
      expect(second.existsSync(), isFalse, reason: 'the old content is gone');
    });

    test(
      'clean empties the folder, and is fine when there is no folder',
      () async {
        await files.clean();
        final a = await files.create('a.pdf');
        await a.writeAsString('1');
        final b = await files.create('b.png');
        await b.writeAsString('2');
        await files.clean();
        expect(Directory('${base.path}/share').listSync(), isEmpty);
      },
    );
  });

  group('FakeShareService (test/support/fake_share.dart)', () {
    test('records what it is given and can answer dismissed or fail', () async {
      final fake = FakeShareService();
      expect(await fake.shareText('a'), ShareOutcome.shared);
      await fake.shareFile(
        path: '/p',
        fileName: 'n.pdf',
        mimeType: 'application/pdf',
      );
      expect(fake.texts, ['a']);
      expect(fake.files.single.fileName, 'n.pdf');
      fake.outcome = ShareOutcome.dismissed;
      expect(await fake.shareText('b'), ShareOutcome.dismissed);
      fake.failure = const ShareFailure(ShareFailureKind.couldNotShare);
      await expectLater(fake.shareText('c'), throwsA(isA<ShareFailure>()));
    });
  });
}
