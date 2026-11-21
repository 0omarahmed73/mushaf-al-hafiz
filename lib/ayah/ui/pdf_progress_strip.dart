import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../pdf/pdf_job.dart';
import '../../theme.dart';
import '../share_service.dart';

/// The strip above the reader's bottom bar while a surah PDF is prepared (spec FR-016, contracts/ui.md):
/// progress and «إلغاء» while it runs, «مشاركة» when the file is ready and the app was not in front to share
/// it by itself, the failure message with «إغلاق». Non-modal: it covers only its own 56 px.
class PdfProgressStrip extends StatelessWidget {
  const PdfProgressStrip({super.key, required this.job, required this.share});

  final PdfJob job;
  final ShareService share;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: job,
      builder: (context, _) => switch (job.state) {
        PdfIdle() => const SizedBox.shrink(),
        final PdfPreparing s => _preparing(s),
        final PdfReady s => _ready(s),
        final PdfFailed s => _failed(s),
      },
    );
  }

  Widget _preparing(PdfPreparing s) {
    final page = math.min(s.done + 1, s.total);
    final title = 'جارٍ تجهيز سورة ${s.surahName}';
    final counter = 'صفحة $page من ${s.total}';
    return _Card(
      progress: s.total == 0 ? null : s.done / s.total,
      semanticsLabel: '$title، $counter',
      child: Row(
        children: [
          Expanded(
            child: _Texts(title: title, subtitle: counter),
          ),
          _StripButton(
            key: const ValueKey('pdf-cancel'),
            label: 'إلغاء',
            onTap: job.cancel,
          ),
        ],
      ),
    );
  }

  Widget _ready(PdfReady s) => _Card(
    liveRegion: true,
    child: Row(
      children: [
        Expanded(
          child: _Texts(title: 'تم تجهيز الملف', subtitle: s.fileName),
        ),
        _StripButton(
          key: const ValueKey('pdf-share'),
          label: 'مشاركة',
          onTap: () => job.shareReady(share),
        ),
        const SizedBox(width: 4),
        _StripButton(
          key: const ValueKey('pdf-close'),
          label: 'إغلاق',
          onTap: job.dismiss,
        ),
      ],
    ),
  );

  Widget _failed(PdfFailed s) => _Card(
    liveRegion: true,
    child: Row(
      children: [
        Expanded(child: _Texts(title: s.message)),
        _StripButton(
          key: const ValueKey('pdf-close'),
          label: 'إغلاق',
          onTap: job.dismiss,
        ),
      ],
    ),
  );
}

/// The card (ivory with a gold border, a charcoal pill in Night Reader), exactly [PdfProgressStrip.height] high, with an optional thin bar.
class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.progress,
    this.semanticsLabel,
    this.liveRegion = false,
  });

  final Widget child;
  final double? progress;
  final String? semanticsLabel;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final media = MediaQuery.of(context);
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      label: semanticsLabel,
      child: Material(
        key: const ValueKey('pdf-strip'),
        color: look.cardFill,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(look.buttonRadius(14)),
          side: BorderSide(color: look.cardBorderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: PdfProgressStrip.height,
          // The strip is exactly 56 px high, so its text grows with the system setting only up to 1.2x.
          child: MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(maxScaleFactor: 1.2),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 14,
                      end: 6,
                    ),
                    child: child,
                  ),
                ),
                if (progress != null)
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: look.accentAlt,
                    backgroundColor: look.line,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Texts extends StatelessWidget {
  const _Texts({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: look.cardInk,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: look.cardMuted),
          ),
      ],
    );
  }
}

/// A text button at least 48 px tall and 48 px wide.
class _StripButton extends StatelessWidget {
  const _StripButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: context.look.doneFill,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
