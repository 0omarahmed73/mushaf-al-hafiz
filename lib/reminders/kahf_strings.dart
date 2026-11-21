// The Arabic strings of the al-Kahf reminder day (feature 007), all in this one file.
//
// CONFIRMED: the owner confirmed every string below as written on 2026-11-21 (Constitution VI, specs/007-kahf-day
// tasks T009); they were proposals before. The two Thursday switch texts are today's; `kKahfTitle` and `kKahfBody` (the
// notification's title and Thursday body) stay in `reminder_planner.dart`.

/// The notification body on Friday (confirmed).
const String kKahfBodyFriday = 'يوم الجمعة: لا تنسَ قراءة سورة الكهف';

/// The name of the group of the two day cards, heard by a screen reader; the cards have no visible heading because
/// Settings has no room for one (confirmed).
const String kKahfDayHeading = 'يوم التذكير';

/// The Thursday card: what is shown (short, so that it fits one line beside the Friday card) and the fuller name a
/// screen reader hears, which says why Thursday (confirmed).
const String kKahfDayThursdayLabel = 'الخميس';
const String kKahfDayThursdayName = 'الخميس (ليلة الجمعة)';

/// The Friday card, shown and heard (confirmed).
const String kKahfDayFridayLabel = 'الجمعة';

/// The al-Kahf switch's title and subtitle when Friday is chosen (confirmed).
const String kKahfSwitchTitleFriday = 'تذكير سورة الكهف يوم الجمعة';
const String kKahfSwitchSubtitleFriday = 'كل جمعة في الوقت الذي تختاره';

/// The name of the notification channel in the phone's own settings; it names no day (confirmed).
const String kKahfChannelName = 'تذكير سورة الكهف';

/// The al-Kahf switch's title and subtitle when Thursday is chosen: today's texts (today's).
const String kKahfSwitchTitleThursday = 'تذكير سورة الكهف ليلة الجمعة';
const String kKahfSwitchSubtitleThursday = 'كل خميس في الوقت الذي تختاره';
