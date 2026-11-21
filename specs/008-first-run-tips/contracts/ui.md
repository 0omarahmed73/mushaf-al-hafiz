# UI contract: First-Run Tips

## The card

| Part | Spec |
|---|---|
| Surface | `Dialog`, `look.barFill`, hairline `look.barBorder`, corner radius `look.cardRadius`, inset 16 px at the sides and 24 px above and below, width at most 440 dp, height `min(available, 520)`; right-to-left |
| Outside touch | does nothing (`barrierDismissible: false`) |
| Back | same as «تخطي» (stores the flag) |
| Body | a `PageView`; every page scrolls on its own: drawing (112 dp high, scaled to fit), title, text |
| Footer (pinned) | the dots, then the buttons |
| Dots | 8 dp circles, the current one a 20 dp pill in `look.accent`, the others `look.textSecondary`; not touch targets; one semantics node «الخطوة N من 6», live |
| Buttons | «تخطي» (`TextButton`, `look.accent`, at the start side = right) and «التالي» (`FilledButton`, at the end side = left); on step 6 only «ابدأ» at the end; each at least 48 dp high; a `Wrap`, so a big font puts them on two lines |
| Swipe | left to right = forward; nothing beyond step 1 and step 6 |
| Motion | slide 250 ms for «التالي»; dots resize 180 ms; the long-press ring pulses 1.4 s; **all of it off under reduced motion** |

## The six steps and every Arabic string

All strings are PROPOSALS written for this feature; the owner confirms them word by word (Constitution VI) before the
feature is done. They live in `lib/onboarding/tips_strings.dart`. N is a number written with Western digits.

| Constant | Text |
|---|---|
| `kTipsDialogLabel` | نصائح لاستخدام التطبيق |
| `kTipsNext` | التالي |
| `kTipsSkip` | تخطي |
| `kTipsStart` | ابدأ |
| `kTipsStepOf(N, 6)` | الخطوة N من 6 |

| # | Picture | Title | Text |
|---|---|---|---|
| 1 | a page with one highlighted line, a pulsing ring and a menu card with three icons | اضغط مطوّلاً على الآية | اضغط مطوّلاً على أي كلمة من الآية، فتظهر قائمتها. منها تفتح تفسير السعدي والترجمة الإنجليزية ومعاني الكلمات، وتشارك الآية أو الصفحة أو السورة. |
| 2 | a finger, an arrow pointing right, the current page and the next one peeking from the left | التنقل بين الصفحات | اسحب الصفحة من اليسار إلى اليمين لتنتقل إلى التالية، كما في المصحف الورقي. اضغط اسم السورة في الأعلى لتفتح الفهرس، أو رقم الصفحة لتنتقل إلى صفحة محددة. |
| 3 | a page with its top and bottom bars, a tap ring, a pinch icon | إخفاء الشريطين والتكبير | اضغط على الصفحة مرة لإخفاء الشريطين العلوي والسفلي، ومرة أخرى لإظهارهما. ضع إصبعين على الصفحة وباعد بينهما لتكبّرها. |
| 4 | two pills (the wird, today) and a card row with a tick | وردك اليومي | في أعلى الصفحة اسم وردك وزر «ملخص اليوم»؛ اضغطه لترى ما عليك قراءته اليوم، ثم اضغط «تم» حين تنتهي منه. ومن «أوراد» في الأسفل تضيف أورادًا أخرى. |
| 5 | an outlined bookmark icon, an arrow, a filled one, and a short list | علاماتك | اضغط أيقونة العلامة تحت رقم الجزء لتعلّم الصفحة، واضغطها مرة أخرى لإزالة العلامة. وتجد كل علاماتك في «علامات» في الأسفل. |
| 6 | the menu icon, an arrow, a text-size icon and a moon icon | الحجم والمظهر | اضغط «القائمة» في الأسفل لتفتح الإعدادات. غيّر منها حجم الخط، واختر المظهر: «زمردي وذهبي» أو «القارئ الليلي». |

Every name in the texts is a name the app really shows: «علامات», «أوراد», «القائمة» (the menu icon's tooltip), «ملخص اليوم»,
«تم», «زمردي وذهبي», «القارئ الليلي». The words «تفسير السعدي» and «الترجمة» come from the ayah menu's own titles; the translation
is English (Saheeh International).

## Semantics

- The dialog: a `Semantics` (`scopesRoute`, `namesRoute`, label `kTipsDialogLabel`) around the card (`Dialog` has no label of its own).
- Each title: a header. The picture: excluded. The text: plain.
- The dots: one node, label «الخطوة N من 6», a live region.
- Buttons: «تخطي», «التالي», «ابدأ» by their text.

## Wiring (the coordinator's, not part of this feature's code)

Read in `lib/main.dart` and `lib/splash/splash_gate.dart` on 2026-11-21: the splash (feature 009) is an overlay above the
whole app (`SplashGate` is the root; the app is its child and is built from the first frame, behind the splash), and its
`onFinished` is called once, after the splash is gone. The tips must wait for it, so the gate is **enabled by the splash**:

```dart
import 'onboarding/tips_gate.dart';
import 'mushaf/reader_screen.dart';

/// True once the splash has gone; the first-run tips wait for it (feature 008).
final ValueNotifier<bool> _splashGone = ValueNotifier<bool>(false);

// main():
runApp(SplashGate(ready: app, onFinished: () => _splashGone.value = true, child: AppWhenReady(app)));

// in _bootApp(), in the MushafApp(...) it returns:
home: ValueListenableBuilder<bool>(
  valueListenable: _splashGone,
  child: const ReaderScreen(),
  builder: (context, gone, reader) => TipsGate(enabled: gone, child: reader!),
),
```

Do it through the `home:` argument that `MushafApp` already has, **not** in the default of `lib/app.dart`: many existing tests
pump `MushafApp` without a `home` (for example through `pumpAppWith`) and would get a popup over the reader on their empty
database. A Settings row that reruns the tips calls `showTips(context)` (`import 'onboarding/tips_gate.dart'`).
