/// The measurement lines of the search (feature 011, research D9; spec SC-004, SC-005; Constitution IV).
///
/// Built with `--dart-define=SEARCH_TRACE=true` the service prints `SEARCH prepare ms=<t> slices=<n>` once, when the text of the
/// ayat is ready, and the screen prints `SEARCH query len=<n> ayat=<total> ms=<t>` for each query (from the change of the field to
/// the frame after the results were built). Built with `--dart-define=SEARCH_BENCH=true` the screen also runs the 20 [benchQueries]
/// through the session when it opens and prints `SEARCHBENCH q=<i> ayat=<total> ms=<t>` for each, because `adb input text` cannot
/// type Arabic. Both are compile-time constants like `FrameTrace.enabled`, so a normal build pays nothing for them; they print to
/// the local log only, write no file, send nothing, and **no line ever holds the text of a query**: only its length, the number of
/// ayat found and milliseconds.
library;

import 'package:flutter/foundation.dart';

abstract final class SearchTrace {
  /// `--dart-define=SEARCH_TRACE=true`: the `SEARCH` lines.
  static const bool enabled = bool.fromEnvironment('SEARCH_TRACE');

  /// `--dart-define=SEARCH_BENCH=true`: the 20 queries of SC-004 are run when the search screen opens and each prints a
  /// `SEARCHBENCH` line.
  static const bool bench = bool.fromEnvironment('SEARCH_BENCH');

  /// `SEARCH prepare ms=<t> slices=<n>`: the ayah text became ready after [ms] milliseconds, worked in [slices] pieces of a few
  /// milliseconds each (the yields to the frames, plus the last piece).
  static String prepareLine(int ms, int slices) =>
      'SEARCH prepare ms=$ms slices=$slices';

  /// `SEARCH query len=<n> ayat=<total> ms=<t>`: a query of [length] characters found [total] ayat and was on screen after [ms].
  static String queryLine(int length, int total, int ms) =>
      'SEARCH query len=$length ayat=$total ms=$ms';

  /// `SEARCHBENCH q=<i> ayat=<total> ms=<t>`: the [index]th of [benchQueries] found [total] ayat in [ms] milliseconds.
  static String benchLine(int index, int total, int ms) =>
      'SEARCHBENCH q=$index ayat=$total ms=$ms';

  /// The one place that prints, to the log only. Callers guard on [enabled] or [bench] so a line is not even built when both
  /// are off; the guard here is the second lock.
  static void emit(String line) {
    if (!enabled && !bench) return;
    debugPrint(line);
  }

  /// The 20 queries of SC-004, in this order: ten one-word (one of them with a typed ؤ), five phrases, «ال», the longest ayah (2:282)
  /// pasted whole as the Mushaf stores it, and three that match nothing. A test checks the counts over the real text and that the
  /// pasted ayah is the stored one, word for word.
  static const List<String> benchQueries = [
    'الرحمن',
    'الله',
    'موسى',
    'ابراهيم',
    'يستهزءون',
    'لؤلؤ',
    'الصلاة',
    'ءامنوا',
    'شيئا',
    'العالمين',
    'بسم الله الرحمن الرحيم',
    'يا ايها الذين امنوا',
    'قل هو الله احد',
    'الحمد لله رب العالمين',
    'ان الله غفور رحيم',
    'ال',
    'يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓاْ إِذَا تَدَايَنتُم بِدَيۡنٍ إِلَىٰٓ أَجَلٖ '
        'مُّسَمّٗى فَٱكۡتُبُوهُۚ وَلۡيَكۡتُب بَّيۡنَكُمۡ كَاتِبُۢ بِٱلۡعَدۡلِۚ وَلَا يَأۡبَ '
        'كَاتِبٌ أَن يَكۡتُبَ كَمَا عَلَّمَهُ ٱللَّهُۚ فَلۡيَكۡتُبۡ وَلۡيُمۡلِلِ '
        'ٱلَّذِي عَلَيۡهِ ٱلۡحَقُّ وَلۡيَتَّقِ ٱللَّهَ رَبَّهُۥ وَلَا يَبۡخَسۡ '
        'مِنۡهُ شَيۡـٔٗاۚ فَإِن كَانَ ٱلَّذِي عَلَيۡهِ ٱلۡحَقُّ سَفِيهًا '
        'أَوۡ ضَعِيفًا أَوۡ لَا يَسۡتَطِيعُ أَن يُمِلَّ هُوَ '
        'فَلۡيُمۡلِلۡ وَلِيُّهُۥ بِٱلۡعَدۡلِۚ وَٱسۡتَشۡهِدُواْ شَهِيدَيۡنِ مِن رِّجَالِكُمۡۖ فَإِن '
        'لَّمۡ يَكُونَا رَجُلَيۡنِ فَرَجُلٞ وَٱمۡرَأَتَانِ مِمَّن تَرۡضَوۡنَ مِنَ '
        'ٱلشُّهَدَآءِ أَن تَضِلَّ إِحۡدَىٰهُمَا فَتُذَكِّرَ إِحۡدَىٰهُمَا ٱلۡأُخۡرَىٰۚ وَلَا '
        'يَأۡبَ ٱلشُّهَدَآءُ إِذَا مَا دُعُواْۚ وَلَا تَسۡـَٔمُوٓاْ أَن '
        'تَكۡتُبُوهُ صَغِيرًا أَوۡ كَبِيرًا إِلَىٰٓ أَجَلِهِۦۚ ذَٰلِكُمۡ أَقۡسَطُ '
        'عِندَ ٱللَّهِ وَأَقۡوَمُ لِلشَّهَٰدَةِ وَأَدۡنَىٰٓ أَلَّا تَرۡتَابُوٓاْ إِلَّآ '
        'أَن تَكُونَ تِجَٰرَةً حَاضِرَةٗ تُدِيرُونَهَا بَيۡنَكُمۡ فَلَيۡسَ عَلَيۡكُمۡ '
        'جُنَاحٌ أَلَّا تَكۡتُبُوهَاۗ وَأَشۡهِدُوٓاْ إِذَا تَبَايَعۡتُمۡۚ وَلَا يُضَآرَّ '
        'كَاتِبٞ وَلَا شَهِيدٞۚ وَإِن تَفۡعَلُواْ فَإِنَّهُۥ فُسُوقُۢ بِكُمۡۗ '
        'وَٱتَّقُواْ ٱللَّهَۖ وَيُعَلِّمُكُمُ ٱللَّهُۗ وَٱللَّهُ بِكُلِّ شَيۡءٍ عَلِيمٞ',
    'ذو القرنين',
    'ظظظظ',
    'قلم رصاص',
  ];
}
