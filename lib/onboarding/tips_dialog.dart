import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'tip_picture.dart';
import 'tip_steps.dart';
import 'tips_strings.dart';

/// How the reader left the tips: through the last step's «ابدأ», or through «تخطي» or the system back. A close with
/// no result at all (a navigation that pops everything, the app being killed) is neither: the tips are not seen.
enum TipsOutcome { finished, skipped }

/// The first-run tips card (feature 008): a `PageView` of [kTipSteps] in the right-to-left direction of the paper Mushaf
/// (a finger moving from left to right shows the next step), the dots, «تخطي» and «التالي», and «ابدأ» on the last step.
///
/// It is meant for `showDialog(barrierDismissible: false)` and pops the route with a [TipsOutcome]. Each step scrolls on
/// its own, so a big system font never hides the dots or the buttons, which are pinned under the pages (research D8). The
/// colours are the chosen look's (research D9). The dialog is right-to-left whatever the app around it says.
class TipsDialog extends StatefulWidget {
  const TipsDialog({super.key});

  @override
  State<TipsDialog> createState() => _TipsDialogState();
}

class _TipsDialogState extends State<TipsDialog> {
  /// The card is never taller than this, nor wider than [_maxWidth] (it is smaller on a small screen).
  static const double _maxHeight = 520;
  static const double _maxWidth = 440;
  static const Duration _slide = Duration(milliseconds: 250);
  static const Duration _dotResize = Duration(milliseconds: 180);
  static const int _last = 5;

  final PageController _pages = PageController();
  int _index = 0;

  /// True while «التالي» slides: a second tap meanwhile is ignored, so two quick taps never skip a step.
  bool _animating = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _close(TipsOutcome outcome) => Navigator.of(context).pop(outcome);

  Future<void> _next() async {
    if (_animating || _index >= _last) return;
    // Reduced motion: the next step is simply there (spec FR-013); one tap is one step.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(_index + 1);
      return;
    }
    _animating = true;
    try {
      await _pages.animateToPage(
        _index + 1,
        duration: _slide,
        curve: Curves.easeOutCubic,
      );
    } finally {
      _animating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(kTipSteps.length == _last + 1);
    final look = context.look;
    final lastStep = _index == _last;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close(TipsOutcome.skipped);
        },
        child: Dialog(
          backgroundColor: look.barFill,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(look.cardRadius),
            side: BorderSide(color: look.barBorder),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, _maxWidth);
              final height = constraints.hasBoundedHeight
                  ? math.min(constraints.maxHeight, _maxHeight)
                  : _maxHeight;
              // The dialog's name and its own route scope for a screen reader (Dialog has no label of its own).
              return Semantics(
                key: const ValueKey('tips-semantics'),
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: kTipsDialogLabel,
                child: SizedBox(
                  key: const ValueKey('tips-dialog'),
                  width: width,
                  height: height,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          key: const ValueKey('tips-pages'),
                          controller: _pages,
                          itemCount: kTipSteps.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (context, i) => _StepPage(
                            index: i,
                            step: kTipSteps[i],
                            active: i == _index,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Dots(
                              index: _index,
                              count: kTipSteps.length,
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : _dotResize,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              // A Wrap, so a big system font puts the buttons on two lines instead of overflowing.
                              child: Wrap(
                                alignment: lastStep
                                    ? WrapAlignment.end
                                    : WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (!lastStep)
                                    TextButton(
                                      key: const ValueKey('tips-skip'),
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(64, 48),
                                      ),
                                      onPressed: () =>
                                          _close(TipsOutcome.skipped),
                                      child: const Text(kTipsSkip),
                                    ),
                                  if (lastStep)
                                    FilledButton(
                                      key: const ValueKey('tips-start'),
                                      onPressed: () =>
                                          _close(TipsOutcome.finished),
                                      child: const Text(kTipsStart),
                                    )
                                  else
                                    FilledButton(
                                      key: const ValueKey('tips-next'),
                                      onPressed: _next,
                                      child: const Text(kTipsNext),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One step: its drawing, its title (a heading) and its text, in a scroll view of its own.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.index,
    required this.step,
    required this.active,
  });

  final int index;
  final TipStep step;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: ValueKey('tips-picture-$index'),
            height: 112,
            child: TipPictureView(picture: step.picture, active: active),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              step.title,
              key: ValueKey('tips-step-title-$index'),
              textAlign: TextAlign.center,
              style: headingStyle(20, look.heading),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.body,
            key: ValueKey('tips-body-$index'),
            style: TextStyle(fontSize: 16, height: 1.7, color: look.text),
          ),
        ],
      ),
    );
  }
}

/// The dots: the current step is a longer pill in the accent colour, the others small round dots, so the difference is
/// not only colour. They are not touch targets and are read by a screen reader as one line, «الخطوة N من 6».
class _Dots extends StatelessWidget {
  const _Dots({
    required this.index,
    required this.count,
    required this.duration,
  });

  final int index;
  final int count;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Semantics(
      key: const ValueKey('tips-step-semantics'),
      label: kTipsStepOf(index + 1, count),
      liveRegion: true,
      excludeSemantics: true,
      child: Row(
        key: const ValueKey('tips-dots'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              key: ValueKey('tips-dot-$i'),
              duration: duration,
              width: i == index ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == index ? look.accent : look.textSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
