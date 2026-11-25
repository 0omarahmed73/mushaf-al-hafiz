// Every Arabic string of the ayah bookmark (feature 013, the spec's Assumptions table; contracts/dart-interfaces.md).
//
// The owner confirmed every string here on 2026-11-25 («كلها تمام», task T048, Constitution VI). «ملاحظة للآية» is the
// owner's own wording for the note action; the rest were proposed by the author and confirmed. Changing one means changing
// test/ayah_bookmarks/ayah_bookmark_strings_test.dart first and asking the owner again. X is the surah's name as the index
// writes it, N the ayah number and P the page, in Western digits like the page number the page draws. The undo label is
// `kBookmarkUndo` of feature 006 («تراجع»).

/// The bookmark row of the ayah sheet while the ayah has no bookmark of the current scope (label and tooltip).
const String kAyahBookmarkAddLabel = 'إضافة علامة على الآية';

/// The bookmark row while the ayah has one.
const String kAyahBookmarkRemoveLabel = 'إزالة العلامة من الآية';

/// What a screen reader hears as the state of the bookmark row (the words of feature 006).
const String kAyahStateOn = 'عليها علامة';
const String kAyahStateOff = 'ليس عليها علامة';

/// The message after an add and after a removal by the bookmark row.
String kAyahBookmarkAdded(String surah, int ayah) =>
    'تمت إضافة علامة على سورة $surah · آية $ayah';
String kAyahBookmarkRemoved(String surah, int ayah) =>
    'تمت إزالة العلامة من سورة $surah · آية $ayah';

/// The note row (the owner's wording) and what a screen reader hears as its state.
const String kAyahNoteLabel = 'ملاحظة للآية';
const String kAyahNoteHas = 'عليها ملاحظة';
const String kAyahNoteNone = 'ليس عليها ملاحظة';

/// The note field: its title, the field's label, the line under it (no bookmark yet / a bookmark exists), the two
/// buttons and the line shown when saving failed.
String kAyahNoteTitle(String surah, int ayah) =>
    'ملاحظة على سورة $surah · آية $ayah';
const String kAyahNoteField = 'الملاحظة';
const String kAyahNoteHintNew = 'ستُضاف علامة على الآية مع الملاحظة';
const String kAyahNoteHintExisting =
    'اترك الحقل فارغًا لإزالة الملاحظة وإبقاء العلامة';
const String kAyahNoteCancel = 'إلغاء';
const String kAyahNoteSave = 'حفظ';
const String kAyahNoteFailed = 'تعذّر الحفظ، حاول مرة أخرى';

/// The row that shows the whole note (the owner's request of 2026-11-25, spec FR-028) and the two buttons under it.
const String kAyahNoteShowLabel = 'عرض الملاحظة';
const String kAyahNoteEdit = 'تعديل';
const String kAyahNoteClose = 'إغلاق';

/// The message after a note created the bookmark, replaced another note, or was cleared.
String kAyahNoteCreated(String surah, int ayah) =>
    'تمت إضافة علامة مع ملاحظة على سورة $surah · آية $ayah';
String kAyahNoteSaved(String surah, int ayah) =>
    'تم حفظ الملاحظة على سورة $surah · آية $ayah';
String kAyahNoteRemoved(String surah, int ayah) =>
    'تمت إزالة الملاحظة من سورة $surah · آية $ayah';

/// The row of an ayah bookmark in «علامات»: its title, its page (as a page row writes it today), the word that marks it,
/// the owner tag of a general bookmark (as today) and the label a screen reader hears.
String kAyahRowTitle(String surah, int ayah) => 'سورة $surah · آية $ayah';
String kAyahRowPage(int page) => 'ص $page';
const String kAyahRowWord = 'آية';
const String kAyahOwnerGeneral = 'عامة';
String kAyahRowLabel(String surah, int ayah, int page, String owner) =>
    'علامة على سورة $surah آية $ayah، صفحة $page، $owner';

/// The Settings switch of the tint and the line under it.
const String kAyahTintTitle = 'تظليل الآيات التي عليها علامة';
const String kAyahTintSubtitle =
    'ظلّ خفيف خلف كل آية عليها علامة في صفحة المصحف';
