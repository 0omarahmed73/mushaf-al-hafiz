// A row or panel on a sheet keeps its own radius in Emerald & Gold and has the card radius in Night Reader
// (spec FR-004; contracts/ui.md ayah menu).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/theme.dart';

void main() {
  test('Emerald keeps what each screen had', () {
    expect(AppLook.emerald.rowRadius(14), 14);
    expect(AppLook.emerald.rowRadius(12), 12);
  });

  test('Night gives every row the card radius', () {
    expect(AppLook.night.rowRadius(14), 20);
    expect(AppLook.night.rowRadius(12), 20);
  });
}
