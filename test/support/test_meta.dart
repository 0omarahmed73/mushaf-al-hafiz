import 'package:mushaf/mushaf/models.dart';

/// A tiny [MushafMeta] with the first two surahs, for tests that only need names and ayah counts.
MushafMeta testMeta() => MushafMeta(
  surahs: const [
    SurahInfo(number: 1, name: 'الفاتحة', ayahs: 7, startPage: 1),
    SurahInfo(number: 2, name: 'البقرة', ayahs: 286, startPage: 2),
  ],
  pageJuz: const [],
  pageHizbQuarter: const [],
  pageSurahs: const [],
  ayahPage: const {},
);

/// Al-Fatiha on page 1 (one page), Al-Baqarah on pages 2..49 (48 pages) and a third surah on page 604 only
/// (named as the last one in the Mushaf; surah numbers here are list positions), for the PDF tests.
MushafMeta pdfMeta() => MushafMeta(
  surahs: const [
    SurahInfo(number: 1, name: 'الفاتحة', ayahs: 7, startPage: 1),
    SurahInfo(number: 2, name: 'البقرة', ayahs: 286, startPage: 2),
    SurahInfo(number: 3, name: 'الإخلاص', ayahs: 4, startPage: 604),
  ],
  pageJuz: const [],
  pageHizbQuarter: const [],
  pageSurahs: const [],
  ayahPage: const {
    '1:1': 1,
    '1:7': 1,
    '2:1': 2,
    '2:286': 49,
    '3:1': 604,
    '3:4': 604,
  },
);
