# UI contract (014)

All strings are proposals (Principle VI). Keys are for tests.

## Bottom bar
- `bar-prayer`: the «مواقيت» item with the mosque icon, where «استماع / قريبًا» was. It has the tooltip «مواقيت الصلاة» and
  opens `PrayerScreen`. The bar's height, the order of the other items and the page rectangle are unchanged.

## PrayerScreen (`prayer-screen`)

**Off** (`prayer-off`):
- A short line: «اعرف مواعيد الصلاة في مكانك، وتنبيه عند كل صلاة. كل ده بيتحسب على موبايلك من غير إنترنت.»
- The button `prayer-enable`: «تشغيل مواقيت الصلاة».

**No place** (`prayer-place`):
- `place-locate`: «حدد موقعي». It asks the approximate location, then reads it. A spinner shows for at most 30 s.
- `place-list`: «اختار المدينة من القائمة».
- If refused or not found, the line `place-failed` reads «مقدرناش نحدد موقعك. اختار مدينتك من القائمة.» and the list opens.
- If refused forever, it also shows `place-settings`: «افتح الإعدادات».

**Showing** (`prayer-day`):
- Header: the place (`prayer-place-name`, with «تقريبًا» when found by location), the Gregorian date and the Hijri date
  (`prayer-hijri`).
- Next prayer card (`prayer-next`): «الصلاة القادمة: العصر» and the countdown «بعد ١:٢٣:٠٤»; it updates every second.
- Six rows (`prayer-row-fajr` … `prayer-row-isha`), each with the name, the time «٤:٣٢ ص» and, for the five prayers, a
  bell icon button (`prayer-bell-<p>`) that cycles sound → silent → off. Its semantics label is the prayer and the state.
  Sunrise has no bell. The next prayer's row is marked with the accent colour and the semantics value «القادمة».
- Lines that appear only when they apply:
  - `exact-off`: «التنبيهات ممكن تتأخر كام دقيقة.» with the button «اسمح بالتوقيت الدقيق».
  - `notif-off`: «الإشعارات مقفولة للتطبيق.» with the button «افتح الإعدادات».
  - `zone-differs`: «توقيت موبايلك غير توقيت المكان ده.» with the button «حدد موقعي».
  - `high-lat`: «في المكان ده الفجر أو العشاء بيتحسب بطريقة تقريبية.»
- Actions:
  - `prayer-month`: «جدول الشهر».
  - `prayer-settings`: «ضبط المواقيت».
  - `prayer-test`: «جرّب التنبيه».
  - `prayer-battery`: «لو التنبيه مبيوصلش» opens a short guide sheet.
  - `prayer-disable`: «إيقاف مواقيت الصلاة».

## Settings sheet (`prayer-settings-sheet`)
- The method (`set-method`): a list of Arabic names; «تلقائي (حسب البلد)» is first.
- The Asr rule (`set-asr`): «الجمهور» / «الحنفي».
- An offset per time (`set-offset-<p>`) as − / + steppers, −30..+30.
- Per prayer (`set-notify-<p>`): a segmented choice «بصوت / صامت / بدون», and «تذكير قبلها» with
  off / 5 / 10 / 15 / 20 / 30 minutes.

## Month (`prayer-month-screen`)
- A row per day with the date, the Hijri day and the six times; today is marked (`month-today`).
- `month-prev` and `month-next` move between months.

## Notifications
- At the prayer: the title «حان الآن موعد صلاة العصر» and the body is the place's name. The channel follows the bell:
  «تنبيه الصلاة» (takbir) or «تنبيه الصلاة (صامت)».
- Before it: «باقي ١٠ دقائق على صلاة العصر», on the channel «تذكير قبل الصلاة».
- Tapping either opens `PrayerScreen`.

## Look and size
- Both looks use `context.look` tokens, with contrast ≥ 4.5:1 (contrast walk).
- At 320 dp with a 2x font: no overflow, and touch targets are 48 dp. Digits are the app's existing time digits.

## Strings added while writing T003 (proposals, pinned by `test/prayer/prayer_strings_test.dart`)
The city search field «ابحث عن مدينتك»; the test notification's body «كده التنبيه شغال.»; the battery guide's text; the
settings labels «طريقة الحساب», «العصر», «تعديل بالدقايق», «لا» (no reminder), «١٥ دقيقة»; the offsets written «−٣» / «+٢»;
the ten method names in Arabic; the Hijri suffix «هـ».
