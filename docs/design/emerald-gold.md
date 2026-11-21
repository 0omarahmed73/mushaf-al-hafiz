# Look: Emerald & Gold (chosen 2026-11-20)

Design canvas with the three explored directions (A Ink & Paper, B Night Reader, C Emerald & Gold):
https://claude.ai/artifact/Bug9MVu2TbGWJtaKGhCSye (private; share it from the page's Share menu).

Direction C is implemented in `lib/theme.dart` and `lib/mushaf/reader_screen.dart`:

| Token | Value | Used for |
|---|---|---|
| green | `#0E3B30` | app background, surah-title banner |
| greenDeep | `#0A2D25` | bottom bar |
| greenLine | `#1E5646` | hairlines |
| paper | `#FBF5E3` | the Mushaf page card |
| ink | `#14231D` | Quran text on the page |
| gold | `#E4C877` | titles, icons, accents |
| goldDark | `#B8923A` | page frame, borders |
| ivory / muted | `#F3EBCB` / `#E8DDB5` | text on green |

Fonts (bundled 2026-11-20, SIL OFL, listed in `docs/research/licenses.md`): Reem Kufi (bold) for headings and the
surah title banner, Cairo (Regular/Medium/SemiBold/Bold, Arabic and Latin in one family; replaced IBM Plex Sans Arabic on 2026-11-20 at the owner's request) for the interface, Amiri Quran for the basmallah.
The About screen (T048) must credit all three.

Open follow-ups:
- The design shows the page number below the page card; the app draws it inside the card.
