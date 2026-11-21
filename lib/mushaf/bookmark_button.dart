import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../motion/fade_in_on_change.dart';
import '../theme.dart';
import 'bookmark_strings.dart';

/// The reader's bookmark icon (feature 006): the outlined «add» bookmark (the same glyph as the sheet's «إضافة علامة»
/// button) while the page shown has no bookmark of the current scope, the filled «added» one while it has one. The
/// glyphs differ from the bottom bar's «علامات» item on purpose, so the two are never mistaken for each other. One tap calls [onPressed]; what the tap does (add, remove, the message) is the reader's.
///
/// It listens to [bookmarked] itself, so a bookmark change rebuilds this icon alone and never the page. The target is
/// 48 x 48, the tooltip and the screen-reader label name the action and the page, and the screen reader hears the
/// state as the value (contracts/ui.md «States»).
class BookmarkButton extends StatelessWidget {
  const BookmarkButton({
    super.key,
    required this.page,
    required this.bookmarked,
    required this.onPressed,
  });

  /// The page shown (1..604), written in the tooltip and the label.
  final int page;

  /// True while the page has a bookmark of the current scope.
  final ValueListenable<bool> bookmarked;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return ValueListenableBuilder<bool>(
      valueListenable: bookmarked,
      builder: (context, on, _) {
        final label = on ? kBookmarkRemove(page) : kBookmarkAdd(page);
        // One node for a screen reader: a button, the action (with the page) as its label, the state as its value.
        return Semantics(
          key: const ValueKey('bookmark-button'),
          button: true,
          label: label,
          value: on ? kBookmarkStateOn : kBookmarkStateOff,
          onTap: onPressed,
          excludeSemantics: true,
          child: IconButton(
            // The icon of the new state is the only one in the tree; it fades in and grows from 0.8 (feature 010, FR-011).
            // The Semantics stays outside, so a screen reader still hears one node.
            icon: FadeInOnChange(
              value: on,
              fromScale: 0.8,
              child: Icon(
                on ? Icons.bookmark_added : Icons.bookmark_add_outlined,
              ),
            ),
            color: on ? look.accent : look.textSecondary,
            tooltip: label,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: onPressed,
          ),
        );
      },
    );
  }
}
