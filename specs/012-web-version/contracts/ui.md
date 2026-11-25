# UI Contract: Web Version (feature 012)

Only what **differs from Android** is listed; every other screen is the Android screen. All Arabic strings below are **proposals** until the owner confirms each one (Principle VI, FR-041, SC-014); the spec's
table of proposed strings is the starting point and rows marked «new» are additions of this plan. Strings live in one file `lib/web/web_strings.dart`; none is machine-translated. Every control is at least 48 px, in
both looks, and reachable by keyboard.

## Strings

| Key | Proposal | Where | Source |
|---|---|---|---|
| `dataNotice` | بياناتك محفوظة في هذا المتصفح على هذا الجهاز فقط. إن مسحت بيانات المتصفح ضاعت أورادك وعلاماتك، فاحتفظ بنسخة احتياطية. | first-use bar; Settings | spec |
| `remindersAndroidOnly` | التذكيرات متاحة في تطبيق أندرويد فقط. المتصفح لا يستطيع تنبيهك وهو مغلق. | Settings, in place of «التذكيرات» | spec |
| `pageLoading` | جارٍ تحميل الصفحة… | the page's waiting state | spec |
| `pageFailed` / `retry` | تعذّر تحميل الصفحة. تحقّق من الاتصال. / إعادة المحاولة | page failure | spec |
| `pageNeedsConnection` | هذه الصفحة تحتاج اتصالًا بالإنترنت مرة واحدة. | page offline | spec |
| `searchPreparing` | جارٍ تجهيز البحث… | search | spec |
| `packButton` | تنزيل المصحف كاملًا للقراءة بلا إنترنت (نحو {N} ميجابايت) | Settings tile; **{N} is computed from `pack.json`**, not 170 (research D10) | spec, number changed |
| `packStop` | إيقاف التنزيل | tile while running | spec |
| `packDone` | المصحف كاملًا متاح الآن بلا إنترنت | tile when complete | spec |
| `privateWindow` | أنت في نافذة خاصة: لن يُحفظ شيء بعد إغلاقها. | bar, every start while `volatile` | spec |
| `shareCopied` | تم نسخ نص الآية | snack bar | spec |
| `fileSaved` | تم تنزيل الملف | snack bar after export | spec |
| `rightsHolder` | إن كنت صاحب حق في أي مورد واعترضت، افتح بلاغًا في صفحة المشروع على GitHub، وسيُزال المورد أو يُسحب الموقع. | About | spec |
| `androidApp` | تطبيق أندرويد | About link | spec |
| `tabTitle` | مصحف الحافظ | browser tab | spec |
| `packConfirmTitle` | تنزيل المصحف كاملًا؟ (new) | size sheet | plan |
| `packStart` / `packCancel` | ابدأ / إلغاء (new) | size sheet | plan |
| `packProgress` | تم تنزيل {done} من {total} ميجابايت (new) | tile while running | plan |
| `packNoSpace` | مساحة المتصفح لا تكفي لتنزيل المصحف كاملًا. (new) | size sheet | plan |
| `packFailed` | تعذّر إكمال التنزيل. اضغط مرة أخرى للمتابعة. (new) | tile | plan |
| `persistGranted` | المتصفح سيحتفظ ببياناتك. (new) | Settings line | plan |
| `persistDenied` | المتصفح قد يمسح بياناتك عند امتلاء الجهاز، فاحتفظ بنسخة احتياطية. (new) | Settings line | plan |
| `updateReady` / `updateApply` | يوجد تحديث جاهز للتطبيق / تطبيق التحديث (new) | Settings line and button | plan |
| `tabBlocked` | التطبيق مفتوح في تبويب آخر. استخدم ذلك التبويب. (new) | one-tab screen | plan |
| `tabRetry` | حاول مرة أخرى (new) | one-tab screen | plan |
| `openSourceLine` | مكوّنات برمجية مفتوحة المصدر (new, only if the owner agrees, research D8) | About | plan |
| `tipsPointer*` | tip texts worded for mouse and keyboard (new; the touch tips of feature 008 stay) | first-run tips on a pointer device | plan |
| `noscript` / `cannotStart` | static Arabic text in `index.html` for «JavaScript is off» and «this browser cannot start the app» (new) | start page | plan |

## Screens that differ

| Screen | Web behaviour | Stays as Android |
|---|---|---|
| First visit | the Mushaf page is the first screen (no home, no consent banner, FR-001); after the tips, **one dismissible bar** with `dataNotice` (not a modal); it is not shown again once dismissed | the tips (feature 008) |
| Reader | mouse drag turns pages; ← next, → previous (next is on the left), `PageDown`/`Space`/`PageUp`, `Home`/`End`; on-screen arrows ≥ 48 px **only after a mouse event**, hidden with the bars; right-click or `Enter` on a focused word opens the ayah sheet; the browser context menu is off over the page only | swipe direction, bars, zoom, 80%–150%, geometry |
| Ayah sheet | no «الصفحة والسورة» heading, no picture entry, no PDF entry, **nothing in their place** (FR-017) | tafsir, translation, meanings, copy, share text (browser share sheet, else copy) |
| Settings | «التذكيرات» section replaced by `remindersAndroidOnly` (no switch, no time, no permission card); a «بياناتك» section: `dataNotice`, export and import buttons, storage line (`privateWindow` when volatile), persistence line, the whole-Mushaf tile, the update line, the build id | the look tile, reading and text size |
| About | Android About plus `rightsHolder` with the Issues address, links to the repository and `androidApp`, optionally `openSourceLine`; links open in a new tab | every credit, `النص القرآني لم يُعدَّل`, the dedication, developer links |
| The whole-Mushaf tile | label with the computed size → size sheet (`packConfirmTitle`, size, `packStart`/`packCancel`) → bar with `packProgress` and `packStop` → `packDone`; reappears as the button if the browser evicted files | |
| One-tab screen | `tabBlocked` and `tabRetry`, in the app's look, nothing else; the database is not opened in this tab | |
| Start screen | static dark page with the app name before Flutter starts (matches the Night look); the same icon in the tab | splash of feature 009 is Android's |

## Layout rules

- One page at a time at every width; at 1920 px the page is the existing landscape layout (centred, same geometry); no screen needs sideways scrolling from 360 px up except a deliberately enlarged page (FR-043, SC-011);
  the pinned rectangles of the reader and the index at 360x800, 800x1280 and 1920x1080 are recorded before any edit and re-checked after.
- Focus ring visible on every focusable control in both looks; dialogs trap focus and `Esc` closes them; the on-screen arrows and the bars are reachable by `Tab`.
- Reduced motion (`prefers-reduced-motion`) removes every animation exactly as on Android (feature 010).
- No control may look as if it works and does not (FR-022): no share-picture or PDF entry, no reminder switch, no notification card.

## Semantics

The existing Android semantics labels are reused; the new bar, the tile and the one-tab screen carry labels equal to their visible text; the progress bar announces its percentage no more than once per 5%.
