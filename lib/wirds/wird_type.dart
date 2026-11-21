/// Wird types (data-model.md). `hifz` and `review` exist in the data now and get their screens in a
/// later feature; only `reading` and `qiyam` can be created in feature 001.
enum WirdType {
  reading,
  hifz,
  review,
  qiyam;

  /// Types the user can create in this feature.
  bool get selectable => this == reading || this == qiyam;

  /// The Arabic name shown in lists and the form.
  String get label => switch (this) {
    reading => 'قراءة',
    hifz => 'حفظ',
    review => 'مراجعة',
    qiyam => 'قيام الليل',
  };
}
