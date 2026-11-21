// The text of the khatm dua and how it is read (spec FR-015, FR-019, SC-006; data-model.md DuaText.paragraphs and
// Dua text (bundled asset).Integrity and .Size).
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/khatm/dua_text.dart';

import '../support/map_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parse', () {
    test('splits at blank lines and drops the final newline only', () {
      final d = DuaText.parse('الأول، بتشكيلٍ.\n\nالثاني  ، بمسافتين\n');
      expect(d.paragraphs, ['الأول، بتشكيلٍ.', 'الثاني  ، بمسافتين']);
    });

    test('one paragraph stays one paragraph', () {
      expect(DuaText.parse('واحد\n').paragraphs, ['واحد']);
      expect(DuaText.parse('واحد').paragraphs, ['واحد']);
    });

    test('text joins the paragraphs by one blank line and equals the file without its final newline', () {
      const file = 'أ\n\nب\n\nج\n';
      expect(DuaText.parse(file).text, 'أ\n\nب\n\nج');
    });

    test('two blank lines in a row never give an empty paragraph', () {
      final d = DuaText.parse('أ\n\n\n\nب\n');
      expect(d.paragraphs, ['أ', 'ب']);
      expect(d.paragraphs.every((p) => p.isNotEmpty), isTrue);
    });

    test('Windows line ends are read as the same blank lines', () {
      expect(DuaText.parse('أ\r\n\r\nب\r\n').paragraphs, ['أ', 'ب']);
    });
  });

  group('load', () {
    test('a missing asset throws DuaUnavailable', () async {
      await expectLater(
        DuaText.load(MapBundle({})),
        throwsA(isA<DuaUnavailable>()),
      );
    });

    test(
      'an empty file and a file of only blank lines throw DuaUnavailable',
      () async {
        for (final text in ['', '\n', '\n\n\n', '   \n\n  \n']) {
          await expectLater(
            DuaText.load(MapBundle({DuaText.assetPath: text})),
            throwsA(isA<DuaUnavailable>()),
            reason: '"${text.replaceAll('\n', r'\n')}"',
          );
        }
      },
    );

    test('a bundle that fails with any error is DuaUnavailable', () async {
      await expectLater(
        DuaText.load(_ThrowingBundle()),
        throwsA(isA<DuaUnavailable>()),
      );
    });
  });

  group('the real asset', () {
    test('is the one path the loader reads', () {
      expect(DuaText.assetPath, 'assets/khatm/dua.txt');
    });

    test(
      'is bundled and the loader gives back its text byte for byte',
      () async {
        final onDisk = File(DuaText.assetPath).readAsStringSync();
        final bundled = await rootBundle.loadString(DuaText.assetPath);
        expect(bundled, onDisk, reason: 'pubspec lists the asset');
        final dua = await DuaText.load(rootBundle);
        expect(
          dua.text,
          onDisk.endsWith('\n')
              ? onDisk.substring(0, onDisk.length - 1)
              : onDisk,
        );
        expect(
          onDisk.endsWith('\n'),
          isTrue,
          reason: 'one final newline (data model)',
        );
      },
    );

    test(
      'is small (under 16 KB), has no empty paragraph and no markup',
      () async {
        final bytes = File(DuaText.assetPath).readAsBytesSync();
        expect(bytes.length, lessThan(16 * 1024));
        final dua = await DuaText.load(rootBundle);
        expect(dua.paragraphs, isNotEmpty);
        expect(dua.paragraphs.every((p) => p.trim().isNotEmpty), isTrue);
        final text = dua.text;
        expect(
          text.contains('\n\n\n'),
          isFalse,
          reason: 'exactly one blank line between paragraphs',
        );
        for (final markup in ['#', '*', '<', '>', '`', '[', ']']) {
          expect(
            text.contains(markup),
            isFalse,
            reason: 'no markup character $markup',
          );
        }
      },
    );

    test('is the app\'s only dua: no other file under assets/khatm', () {
      final files = Directory('assets/khatm')
          .listSync()
          .map((e) => e.path)
          .toList();
      expect(files, ['assets/khatm/dua.txt']);
    });
  });

  // The wording the owner confirmed word by word on 2026-11-21 (tasks T011). If this fails, the file was changed: the
  // owner must confirm the new wording again before the test is updated (Constitution III and VI, spec FR-016).
  group('the wording confirmed by the owner', () {
    final bytes = File(DuaText.assetPath).readAsBytesSync();

    test('eleven paragraphs, ten of them ending with ۞', () {
      final d = DuaText.parse(File(DuaText.assetPath).readAsStringSync());
      expect(d.paragraphs, hasLength(11));
      expect(
        d.paragraphs.first,
        startsWith('اللَّهُمَّ ارْحَمْنِي بالقُرْءَانِ'),
      );
      expect(d.paragraphs.last, endsWith('وَسَلَّمَ تَسْلِيمًا كَثِيراً.'));
      expect(d.paragraphs.where((p) => p.endsWith('\u06DE')), hasLength(10));
    });

    test('the bytes are the confirmed ones (size and FNV-1a checksum)', () {
      var h = 2166136261;
      for (final b in bytes) {
        h = ((h ^ b) * 16777619) & 0xFFFFFFFF;
      }
      expect(bytes.length, 4479);
      expect(h, 973973426);
    });
  });
}

class _ThrowingBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(StateError('boom'));

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) => Future.error(StateError('boom'));
}
