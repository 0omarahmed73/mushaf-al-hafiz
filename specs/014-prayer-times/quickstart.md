# Quickstart: validating prayer times (014)

## Automated

```bash
flutter test test/prayer/
flutter test        # the whole suite: wird reminder tests and layout tests unchanged and green
flutter analyze
```

The tests must show:

- **Calculation**: the Cairo, Alexandria and Aswan fixtures (12 dates each) and the Makkah fixture are within ±1 minute
  (SC-001).
- **Planner**: 48 hours of items; nothing in the past; ids unique and in the prayer range; nothing when off; exact flags
  follow the permission.
- **Merged manifest**: `ACCESS_COARSE_LOCATION` and `SCHEDULE_EXACT_ALARM` are added; there is no `INTERNET`,
  `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` or `USE_EXACT_ALARM` (SC-007). Checked with
  `aapt2 dump permissions` on the release APK.
- **Screen**: Emerald and Night; 320 dp with a 2x font; every key of contracts/ui.md.
- **Licences**: `takbir.ogg` exists and has its line in `licenses.md`. This is the release blocker test (research D8).

## On the owner's Samsung (Principle IX; needs his «سطّب» and a backup first)

1. The app opens on the Mushaf; the bar shows «مواقيت».
2. Turn it on, tap «حدد موقعي», and allow the approximate location. The place and its times show. Compare with the
   mosque or the Egyptian timetable (±1 minute).
3. Deny the location on a second try (clear the app's permission first). The city list opens; search «الاسكندريه»
   (without the hamza) and pick it.
4. With exact timing allowed, set Dhuhr or Asr to sound with a 5-minute reminder. Close the app and lock the screen. Both
   notifications arrive on time, and the takbir plays at the prayer.
5. Turn exact timing off in the system settings. The `exact-off` line shows, and the next notification arrives within
   15 minutes.
6. Restart the phone without opening the app. The next prayer's notification still arrives.
7. Set the bell to silent for one prayer: the notification shows with no sound.
8. Do a backup, change the settings, and restore: the settings come back. A restore of a pre-014 backup keeps the
   current prayer settings.
9. Night look, a big system font: nothing is cut off.
