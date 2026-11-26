import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/links.dart';
import 'package:mushaf/settings/about_screen.dart';

import '../support/harness.dart';

class _FakeOpener implements LinkOpener {
  final List<String> opened = [];
  bool result = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}

void main() {
  late _FakeOpener opener;
  late List<String> copied;

  setUp(() => opener = _FakeOpener());

  Future<void> pumpAbout(
    WidgetTester t, {
    List<DeveloperLink> links = kDeveloperLinks,
  }) async {
    copied = [];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpAppWith(
      t,
      home: AboutScreen(links: links, linkOpener: opener),
      defaults: false,
    );
  }

  const gitHub = 'https://github.com/example-user';
  const withUrls = [
    DeveloperLink(
      'LinkedIn',
      Icons.work_outline,
      'https://www.linkedin.com/in/example-user',
    ),
    DeveloperLink('GitHub', Icons.code, gitHub),
    DeveloperLink('Portfolio', Icons.language, 'https://example.dev'),
  ];

  // The public release (owner's decision of 2026-11-21): the app is free and non-commercial, not «personal», and every text
  // on this screen says so the same way (docs/release/AUDIT.md section 7).
  testWidgets(
    'the screen calls the app free and non-commercial, never personal',
    (t) async {
      await pumpAbout(t);
      await t.dragUntilVisible(
        find.textContaining(
          'تطبيق مجاني غير تجاري، بلا إعلانات وبلا تتبّع، ويعمل بلا إنترنت.',
        ),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.textContaining('شخصي', skipOffstage: false), findsNothing);
      // Feature 014 added a block below this line, so the credit above may be out of the list's cache: scroll up to it.
      await t.dragUntilVisible(
        find.textContaining('تُستعمل في تطبيق مجاني غير تجاري، مع ذكر مصدرها هنا'),
        find.byType(ListView),
        const Offset(0, 200),
      );
      expect(
        find.textContaining(
          'تُستعمل في تطبيق مجاني غير تجاري، مع ذكر مصدرها هنا',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the dedication says the app is a sadaqah jariyah for the grandmother and the aunt',
    (t) async {
      await pumpAbout(t);
      expect(find.byKey(const ValueKey('dedication')), findsOneWidget);
      expect(find.text('إهداء'), findsOneWidget);
      expect(find.text('هذا التطبيق صدقة جارية'), findsOneWidget);
      expect(find.text('عن جدتي وخالتي'), findsOneWidget);
      expect(
        find.text('اللهم تقبّل منهما، واجعله في ميزان حسناتهما'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the developer\'s name and role are shown with an emblem and three link rows',
    (t) async {
      await pumpAbout(t);
      expect(find.byKey(const ValueKey('developer')), findsOneWidget);
      expect(
        find.text('ع'),
        findsOneWidget,
        reason: 'the emblem carries the first letter of the name',
      );
      expect(find.text('عمر أ. سعيد'), findsOneWidget);
      expect(find.text('Full Stack Developer'), findsOneWidget);
      for (final label in ['LinkedIn', 'GitHub', 'Portfolio']) {
        expect(
          find.byKey(ValueKey('link-$label')),
          findsOneWidget,
          reason: label,
        );
        expect(find.text(label), findsOneWidget, reason: label);
      }
    },
  );

  testWidgets(
    'the default links are exactly the developer\'s three addresses',
    (t) async {
      expect(
        {for (final l in kDeveloperLinks) l.label: l.url},
        {
          'LinkedIn': 'https://linkedin.com/in/0omarahmed73',
          'GitHub': 'https://github.com/0omarahmed73/',
          'Portfolio': 'https://www.omarasaeed.dev/',
        },
      );
      await pumpAbout(t);
      for (final shown in [
        'linkedin.com/in/0omarahmed73',
        'github.com/0omarahmed73',
        'omarasaeed.dev',
      ]) {
        expect(find.text(shown), findsOneWidget, reason: shown);
      }
      await t.tap(find.byKey(const ValueKey('link-Portfolio')));
      await settle(t);
      expect(opener.opened, ['https://www.omarasaeed.dev/']);
    },
  );

  test('shownAddress drops the scheme, www and the trailing slash', () {
    expect(
      shownAddress('https://github.com/0omarahmed73/'),
      'github.com/0omarahmed73',
    );
    expect(shownAddress('https://www.omarasaeed.dev/'), 'omarasaeed.dev');
    expect(
      shownAddress('https://linkedin.com/in/0omarahmed73'),
      'linkedin.com/in/0omarahmed73',
    );
    expect(shownAddress('not a url'), 'not a url');
  });

  testWidgets('a link that has not been given yet is switched off', (t) async {
    await pumpAbout(
      t,
      links: const [
        DeveloperLink('LinkedIn', Icons.work_outline, null),
        DeveloperLink('GitHub', Icons.code, null),
      ],
    );
    for (final label in ['LinkedIn', 'GitHub']) {
      expect(
        t.widget<InkWell>(find.byKey(ValueKey('link-$label'))).onTap,
        isNull,
        reason: label,
      );
    }
    await t.tap(find.byKey(const ValueKey('link-GitHub')), warnIfMissed: false);
    expect(opener.opened, isEmpty);
  });

  testWidgets('tapping a link opens exactly that address', (t) async {
    await pumpAbout(t, links: withUrls);
    await t.tap(find.byKey(const ValueKey('link-GitHub')));
    await settle(t);
    expect(opener.opened, [gitHub]);
    expect(copied, isEmpty);
    expect(find.text('تعذّر فتح الرابط. تم نسخه.'), findsNothing);
  });

  testWidgets(
    'if the browser cannot open it the address is copied and the screen says so',
    (t) async {
      await pumpAbout(t, links: withUrls);
      opener.result = false;
      await t.tap(find.byKey(const ValueKey('link-GitHub')));
      await settle(t);
      expect(copied, [gitHub]);
      expect(find.text('تعذّر فتح الرابط. تم نسخه.'), findsOneWidget);
    },
  );

  testWidgets('a long press copies the address without opening it', (t) async {
    await pumpAbout(t, links: withUrls);
    await t.longPress(find.byKey(const ValueKey('link-GitHub')));
    await settle(t);
    expect(copied, [gitHub]);
    expect(opener.opened, isEmpty);
    expect(find.text('تم نسخ الرابط'), findsOneWidget);
  });

  testWidgets('the link rows are at least 44 logical pixels tall', (t) async {
    await pumpAbout(t, links: withUrls);
    for (final label in ['LinkedIn', 'GitHub', 'Portfolio']) {
      expect(
        t.getSize(find.byKey(ValueKey('link-$label'))).height,
        greaterThanOrEqualTo(44),
        reason: label,
      );
    }
  });

  testWidgets('the whole screen fits a small phone without overflow', (
    t,
  ) async {
    await pumpAbout(t, links: withUrls);
    t.view.physicalSize = const Size(320, 640);
    await t.pump();
    await t.scrollUntilVisible(
      find.textContaining('بلا إعلانات'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('بلا إعلانات'), findsOneWidget);
  });

  group(
    'credits for the sources of the ayah actions (spec FR-020, SC-008)',
    () {
      const tafsir = 'تفسير السعدي — تيسير الكريم الرحمن';
      const translation = 'ترجمة Saheeh International';
      const meanings =
          'معاني الكلمات — ابن الهائم (التبيان) وابن الجوزي (تذكرة الأريب)';
      const words = 'كلمات النص القرآني';

      Future<void> show(WidgetTester t, String text) async {
        await t.scrollUntilVisible(
          find.text(text),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await t.ensureVisible(find.text(text));
        await t.pump();
      }

      testWidgets(
        'each of the four sources has a line with its provider and version',
        (t) async {
          await pumpAbout(t);
          for (final (name, provider, version) in [
            (tafsir, 'QUL (Tarteel)', '2025-05-26'),
            (translation, 'Tanzil Project', '2011-04-24'),
            (meanings, 'الموسوعة القرآنية Quranpedia', '2026-11-14'),
            (words, 'QUL (Tarteel) · KFGQPC Hafs', '2025-05-28'),
          ]) {
            await show(t, name);
            expect(find.text(name), findsOneWidget, reason: name);
            expect(
              find.text('$provider · الإصدار $version'),
              findsOneWidget,
              reason: name,
            );
          }
        },
      );

      testWidgets('a credit shows its address and tapping opens the link', (
        t,
      ) async {
        await pumpAbout(t);
        await show(t, translation);
        expect(find.text('tanzil.net/trans/en.sahih'), findsOneWidget);
        await t.tap(find.text(translation));
        await settle(t);
        expect(opener.opened, ['https://tanzil.net/trans/en.sahih']);
      });

      testWidgets('if the browser cannot open a credit its address is copied', (
        t,
      ) async {
        await pumpAbout(t);
        opener.result = false;
        await show(t, meanings);
        await t.tap(find.text(meanings));
        await settle(t);
        expect(copied, ['https://quranpedia.net/dumps']);
        expect(find.text('تعذّر فتح الرابط. تم نسخه.'), findsOneWidget);
      });

      testWidgets(
        'the credit rows are at least 48 px tall and are labelled buttons',
        (t) async {
          final handle = t.ensureSemantics();
          await pumpAbout(t);
          for (final name in [tafsir, translation, meanings, words]) {
            await show(t, name);
            final row = find.ancestor(
              of: find.text(name),
              matching: find.byType(InkWell),
            );
            expect(t.getSize(row.first).height, greaterThanOrEqualTo(48));
            final node = t.getSemantics(row.first);
            expect(node.label, contains(name));
            expect(node.flagsCollection.isButton, isTrue);
          }
          handle.dispose();
        },
      );

      test('the credits agree with the sources the assets were built from', () {
        final built = jsonDecode(
          File('assets/ayah/sources.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final sources = (built['sources'] as List).cast<Map<String, dynamic>>();
        expect(sources, isNotEmpty);
        for (final source in sources) {
          final link = source['link'] as String;
          final version = source['version'] as String;
          final credit = kSourceCredits.where((c) => c.link == link);
          expect(credit, isNotEmpty, reason: 'no credit for $link');
          expect(
            credit.any((c) => c.version == version),
            isTrue,
            reason: '$link is credited with another version than $version',
          );
        }
        expect(kSourceCredits, hasLength(4));
      });

      testWidgets('the statement that the Quran text was not modified stays', (
        t,
      ) async {
        await pumpAbout(t);
        expect(find.text('النص القرآني لم يُعدَّل'), findsOneWidget);
      });
    },
  );

  test('PlatformLinkOpener refuses anything that is not https', () async {
    expect(
      await const PlatformLinkOpener().open('http://example.com'),
      isFalse,
    );
    expect(
      await const PlatformLinkOpener().open('javascript:alert(1)'),
      isFalse,
    );
    expect(await const PlatformLinkOpener().open('not a url'), isFalse);
  });
}
