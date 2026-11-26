// About credits the resources of feature 014 (FR-026, Principle V).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/settings/about_screen.dart';

void main() {
  test('the takbir names its reciter and its source', () {
    expect(
      AboutScreen.prayerCredits,
      contains((
        'محمد الدمرداش',
        'تكبيرة تنبيه الصلاة (من أذانه)',
        'assabile.com',
      )),
    );
  });

  test('adhan_dart and GeoNames are credited with their licences', () {
    final rows = AboutScreen.prayerCredits;
    expect(
      rows,
      contains(('adhan_dart', 'حساب مواقيت الصلاة على الهاتف', 'رخصة MIT')),
    );
    expect(
      rows,
      contains((
        'GeoNames',
        'قائمة المدن لمواقيت الصلاة',
        'رخصة CC BY 4.0 · geonames.org',
      )),
    );
  });
}
