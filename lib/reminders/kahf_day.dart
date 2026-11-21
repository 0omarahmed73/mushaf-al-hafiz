/// The weekday of the al-Kahf reminder (feature 007): Thursday, which is the night of Friday and was the only
/// choice before, or Friday. No imports, so the planner, the repository and the settings screen can all use it.
enum KahfDay {
  thursday('thursday', DateTime.thursday, 21 * 60),
  friday('friday', DateTime.friday, 10 * 60);

  const KahfDay(this.storageValue, this.weekday, this.defaultMinutes);

  /// What is stored in the `kahfDay` setting (and in a backup file).
  final String storageValue;

  /// `DateTime.thursday` or `DateTime.friday`, the local weekday the reminder falls on.
  final int weekday;

  /// The hour (minutes after midnight) used while the user has not chosen one: 21:00 on Thursday, the evening before
  /// the day of Friday, and 10:00 on Friday itself (the owner's answer of 2026-11-21).
  final int defaultMinutes;

  /// The day stored as [raw]; Thursday for null and for any text that is not a storage value (a missing setting, or
  /// a value written by a version of the app that knows more days).
  static KahfDay fromStorage(String? raw) => KahfDay.values.firstWhere(
    (d) => d.storageValue == raw,
    orElse: () => KahfDay.thursday,
  );
}
