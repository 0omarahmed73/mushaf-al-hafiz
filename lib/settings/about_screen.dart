import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../khatm/dua_strings.dart';
import '../links.dart';
import '../look/wird_marker.dart';
import '../mushaf/mushaf_page.dart' show StarOrnament;
import '../theme.dart';

/// One of the developer's links. A null [url] shows the button switched off.
class DeveloperLink {
  const DeveloperLink(this.label, this.icon, this.url);

  final String label;
  final IconData icon;
  final String? url;
}

const List<DeveloperLink> kDeveloperLinks = [
  DeveloperLink(
    'LinkedIn',
    Icons.work_outline,
    'https://linkedin.com/in/0omarahmed73',
  ),
  DeveloperLink('GitHub', Icons.code, 'https://github.com/0omarahmed73/'),
  DeveloperLink('Portfolio', Icons.language, 'https://www.omarasaeed.dev/'),
];

/// `github.com/0omarahmed73` for `https://github.com/0omarahmed73/`: the address without the scheme,
/// `www.` or trailing slash, for showing under a link's name.
String shownAddress(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host.isEmpty) return url;
  final host = u.host.startsWith('www.') ? u.host.substring(4) : u.host;
  final path = u.path.endsWith('/')
      ? u.path.substring(0, u.path.length - 1)
      : u.path;
  return host + path;
}

/// One source of the ayah actions (tafsir, translation, word meanings, Quran words) with where it comes
/// from and which file version the app bundles (spec FR-020, contracts/ui.md). Tapping it opens [link].
class SourceCredit {
  const SourceCredit({
    required this.name,
    required this.provider,
    required this.link,
    required this.version,
  });

  final String name;
  final String provider;
  final String link;
  final String version;
}

/// The same links and versions as `assets/ayah/sources.json` (a test compares them).
const List<SourceCredit> kSourceCredits = [
  SourceCredit(
    name: 'تفسير السعدي — تيسير الكريم الرحمن',
    provider: 'QUL (Tarteel)',
    link: 'https://qul.tarteel.ai/resources/tafsir/24',
    version: '2025-05-26',
  ),
  SourceCredit(
    name: 'ترجمة Saheeh International',
    provider: 'Tanzil Project',
    link: 'https://tanzil.net/trans/en.sahih',
    version: '2011-04-24',
  ),
  SourceCredit(
    name: 'معاني الكلمات — ابن الهائم (التبيان) وابن الجوزي (تذكرة الأريب)',
    provider: 'الموسوعة القرآنية Quranpedia',
    link: 'https://quranpedia.net/dumps',
    version: '2026-11-14',
  ),
  SourceCredit(
    name: 'كلمات النص القرآني',
    provider: 'QUL (Tarteel) · KFGQPC Hafs',
    link: 'https://qul.tarteel.ai/resources/translation/312',
    version: '2025-05-28',
  ),
];

/// The dedication, the developer, the statement that the Quran text was not modified, and credits for
/// everything the app is built from (spec FR-041, Constitution V).
class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    this.links = kDeveloperLinks,
    this.linkOpener = const PlatformLinkOpener(),
  });

  final List<DeveloperLink> links;
  final LinkOpener linkOpener;

  static const String appName = 'مصحف الحافظ';
  static const String textNotModified = 'النص القرآني لم يُعدَّل';

  static const String dedicationTitle = 'إهداء';
  static const String dedicationLine = 'هذا التطبيق صدقة جارية';
  static const String dedicationFor = 'عن جدتي وخالتي';
  static const String dedicationDua =
      'اللهم تقبّل منهما، واجعله في ميزان حسناتهما';

  static const String developerName = 'عمر أ. سعيد';
  static const String developerRole = 'Full Stack Developer';

  /// (name, what it is used for, licence or note)
  static const List<(String, String, String)> credits = [
    ('Tanzil', 'بيانات السور والأجزاء والأرباع', 'tanzil.net'),
    (
      'QUL (Quranic Universal Library) من Tarteel',
      'تخطيط صفحات المصحف وبيانات الكلمات',
      'qul.tarteel.ai',
    ),
    (
      'مجمع الملك فهد لطباعة المصحف الشريف',
      'خطوط مصحف المدينة النبوية (QCF V2، طبعة 1421هـ)',
      'تُستعمل في تطبيق مجاني غير تجاري، مع ذكر مصدرها هنا',
    ),
    ('Amiri Quran', 'خط البسملة', 'رخصة الخطوط المفتوحة SIL OFL'),
    ('Reem Kufi', 'خط العناوين', 'رخصة الخطوط المفتوحة SIL OFL'),
    ('Cairo', 'خط الواجهة', 'رخصة الخطوط المفتوحة SIL OFL'),
    (kDuaCreditName, kDuaCreditUse, kDuaCreditNote),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await linkOpener.open(url)) return;
    await Clipboard.setData(ClipboardData(text: url));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط. تم نسخه.')),
      );
  }

  Future<void> _copy(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
          children: [
            Text(appName, style: headingStyle(30, look.heading)),
            const SizedBox(height: 6),
            Text(
              'مصحف المدينة النبوية، طبعة 1421هـ، برواية حفص عن عاصم',
              style: TextStyle(
                fontSize: 14,
                color: look.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            const _Dedication(),
            const _Gap(),
            _Developer(
              links: links,
              onOpen: (url) => _open(context, url),
              onCopy: (url) => _copy(context, url),
            ),
            const _Gap(),
            const _TextNotModified(),
            const SizedBox(height: 26),
            Text(
              'المصادر والشكر',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: look.textSecondary,
              ),
            ),
            for (var i = 0; i < credits.length; i++) ...[
              if (i > 0) const _Hairline(),
              _Credit(credits[i]),
            ],
            for (final source in kSourceCredits) ...[
              const _Hairline(),
              _SourceCreditRow(
                source,
                onOpen: () => _open(context, source.link),
              ),
            ],
            const _Hairline(),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'تطبيق مجاني غير تجاري، بلا إعلانات وبلا تتبّع، ويعمل بلا إنترنت.',
                style: TextStyle(
                  fontSize: 13,
                  color: look.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.look.line);
}

/// Space and a hairline between the big blocks.
class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 22),
    child: _Hairline(),
  );
}

/// The focal point: framed like a Mushaf page, with a title banner like a surah's.
class _Dedication extends StatelessWidget {
  const _Dedication();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final bannerTitle = headingStyle(
      22,
      look.accent,
    ).copyWith(height: 1.25, leadingDistribution: TextLeadingDistribution.even);
    return DecoratedBox(
      key: const ValueKey('dedication'),
      decoration: BoxDecoration(
        border: Border.all(color: look.ring),
        borderRadius: BorderRadius.circular(look.cardRadius + 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: look.cardFill,
            border: Border.all(
              color: look.cardBorderStrong,
              width: look.strongBorderWidth,
            ),
            borderRadius: BorderRadius.circular(look.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            child: Column(
              children: [
                Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: look.background,
                    border: Border.all(color: look.controlBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(look.rowRadius(10)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StarOrnament(color: look.accent),
                      const SizedBox(width: 16),
                      // Shrinks the title only when a very large system font would not leave it room.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AboutScreen.dedicationTitle,
                            style: bannerTitle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      StarOrnament(color: look.accent),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AboutScreen.dedicationLine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: look.cardInk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AboutScreen.dedicationFor,
                  textAlign: TextAlign.center,
                  style: headingStyle(30, look.doneFill).copyWith(height: 1.4),
                ),
                const SizedBox(height: 14),
                Text(
                  AboutScreen.dedicationDua,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: look.cardMuted,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The developer: an emblem beside the name and role, then one full-width row per link. Quieter than
/// the dedication (a dark card, not the ivory frame) so the dedication stays the focal point.
class _Developer extends StatelessWidget {
  const _Developer({
    required this.links,
    required this.onOpen,
    required this.onCopy,
  });

  final List<DeveloperLink> links;
  final void Function(String url) onOpen;
  final void Function(String url) onCopy;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Material(
      key: const ValueKey('developer'),
      color: look.barFill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: look.cardBorderStrong, width: 1.5),
        borderRadius: BorderRadius.circular(look.rowRadius(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                const _Emblem(letter: 'ع'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AboutScreen.developerName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: look.text,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AboutScreen.developerRole,
                        style: TextStyle(
                          fontSize: 15,
                          color: look.accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final link in links) ...[
            const _Hairline(),
            _LinkTile(link: link, onOpen: onOpen, onCopy: onCopy),
          ],
        ],
      ),
    );
  }
}

/// A full-width link row: icon, name, the address under it, and an arrow out. A tap opens the link,
/// a long press copies it, and a link that has not been given yet is switched off.
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.link,
    required this.onOpen,
    required this.onCopy,
  });

  final DeveloperLink link;
  final void Function(String url) onOpen;
  final void Function(String url) onCopy;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final url = link.url;
    final enabled = url != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? '${link.label}، ${shownAddress(url)}' : link.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: InkWell(
          key: ValueKey('link-${link.label}'),
          onTap: enabled ? () => onOpen(url) : null,
          onLongPress: enabled ? () => onCopy(url) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: look.controlBorder, width: 1.2),
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(link.icon, size: 20, color: look.accent),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          link.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: look.text,
                          ),
                        ),
                        if (enabled)
                          Text(
                            shownAddress(url),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 12,
                              color: look.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.north_east, size: 18, color: look.accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The developer's emblem: the eight-pointed star of a rub' al-hizb marker, as in the Mushaf's own
/// quarter-hizb sign, around the first letter of the name.
class _Emblem extends StatelessWidget {
  const _Emblem({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final accent = context.look.accent;
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: _RubElHizbPainter(accent),
        child: Center(
          child: Text(
            letter,
            style: headingStyle(24, accent).copyWith(height: 1.2),
          ),
        ),
      ),
    );
  }
}

class _RubElHizbPainter extends CustomPainter {
  const _RubElHizbPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final half = size.shortestSide / 2 - 1.5;
    final side = half * math.sqrt2; // a square inscribed in the circle
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.08);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final angle in [0.0, math.pi / 4]) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: side,
        height: side,
      );
      canvas
        ..drawRect(rect, fill)
        ..drawRect(rect, line)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_RubElHizbPainter old) => old.color != color;
}

class _TextNotModified extends StatelessWidget {
  const _TextNotModified();

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return DecoratedBox(
      key: const ValueKey('text-not-modified'),
      decoration: BoxDecoration(
        border: Border.all(color: look.controlBorder, width: 1.5),
        borderRadius: BorderRadius.circular(look.rowRadius(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, color: look.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AboutScreen.textNotModified,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: look.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit(this.credit);

  final (String, String, String) credit;

  @override
  Widget build(BuildContext context) {
    final (name, use, note) = credit;
    final look = context.look;
    final quiet = look.textDim;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          WirdMarker(color: look.accentAlt),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: look.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  use,
                  style: TextStyle(fontSize: 13, color: look.textSecondary),
                ),
                Text(note, style: TextStyle(fontSize: 12, color: quiet)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A source with its provider, version and address; a tap opens the link (or copies it), at least 48 px tall.
class _SourceCreditRow extends StatelessWidget {
  const _SourceCreditRow(this.source, {required this.onOpen});

  final SourceCredit source;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final quiet = look.textDim;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${source.name}، ${source.provider}، الإصدار ${source.version}',
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                WirdMarker(color: look.accentAlt),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: look.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${source.provider} · الإصدار ${source.version}',
                        style: TextStyle(
                          fontSize: 13,
                          color: look.textSecondary,
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          shownAddress(source.link),
                          style: TextStyle(fontSize: 12, color: quiet),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.open_in_new, size: 18, color: quiet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
