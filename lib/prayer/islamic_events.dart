// The Islamic days the month table names (the owner, 2026-11-26), by their fixed Hijri date. The app's Hijri calendar
// is tabular (research D9), so a day can differ by one from the month as announced; the names are proposals until the
// owner confirms them (Principle VI).
import 'hijri.dart';

/// (Hijri month, day) → the day's name.
const Map<(int, int), String> kIslamicEvents = {
  (1, 1): 'رأس السنة الهجرية',
  (1, 10): 'يوم عاشوراء',
  (3, 12): 'المولد النبوي',
  (9, 1): 'أول رمضان',
  (9, 21): 'العشر الأواخر من رمضان',
  (10, 1): 'عيد الفطر',
  (12, 9): 'يوم عرفة',
  (12, 10): 'عيد الأضحى',
  (12, 11): 'أيام التشريق',
  (12, 12): 'أيام التشريق',
  (12, 13): 'أيام التشريق',
};

/// The name of the Islamic day [h] falls on, or null.
String? islamicEvent(HijriDate h) => kIslamicEvents[(h.month, h.day)];
