import 'package:flutter/widgets.dart';

import 'splash_palette.dart';

/// Shows a box in the night colour until [app] completes, then the app it produced. The splash is drawn over it while the app
/// loads (spec FR-007); the dark colour means nothing light can show if the splash is skipped before the app is ready.
///
/// If starting the app failed the error is rethrown from `build`, so it is seen as it was before the splash existed
/// (research D1) instead of being hidden behind a dark screen.
class AppWhenReady extends StatelessWidget {
  const AppWhenReady(this.app, {super.key});

  final Future<Widget> app;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: app,
      builder: (context, snapshot) {
        final error = snapshot.error;
        if (error != null) {
          Error.throwWithStackTrace(
            error,
            snapshot.stackTrace ?? StackTrace.current,
          );
        }
        return snapshot.data ??
            const ColoredBox(color: SplashColors.background);
      },
    );
  }
}
