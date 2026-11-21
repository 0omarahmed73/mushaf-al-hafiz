/// Decides whether one drag at the last page of the Mushaf opens the khatm dua (spec FR-001).
///
/// At the last page the pager is clamped, so a forward drag arrives as positive overscroll while the finger is
/// down and the release speed arrives with the end of the drag (research D1). The reader feeds this rule with
/// those two facts and opens the dua when [end] answers true. No Flutter import: the rule is a function of one
/// gesture only. Whether a dua is already open is the reader's business, not this rule's.
class LastPageSwipe {
  /// A slow, deliberate drag opens the dua from this much forward travel (logical pixels, the size of a touch
  /// target).
  static const double minDistance = 48;

  /// A flick opens it from this much forward travel (about the touch slop)...
  static const double minFlingDistance = 16;

  /// ...when it is released at least this fast, in the forward direction (logical pixels per second).
  static const double minFlingVelocity = 300;

  double _distance = 0;

  /// The forward travel of the gesture being followed.
  double get distance => _distance;

  /// A new gesture begins: forget the last one.
  void start() => _distance = 0;

  /// The pager was pulled [delta] logical pixels past the last page. Only forward movement (positive) counts; a
  /// negative value is the other end of the Mushaf, page 1.
  void overscroll(double delta) {
    if (delta > 0) _distance += delta;
  }

  /// The finger left the screen at [velocity] logical pixels per second (positive: forward). True when this
  /// gesture opens the dua. Always clears the distance, so one gesture can open it only once.
  bool end({required double velocity}) {
    final travelled = _distance;
    _distance = 0;
    return travelled >= minDistance ||
        (travelled >= minFlingDistance && velocity >= minFlingVelocity);
  }
}
