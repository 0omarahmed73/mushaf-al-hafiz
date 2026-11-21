import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/digits.dart';

TextEditingValue typed(String text) => TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

void main() {
  test('asciiDigits turns Arabic-Indic and Persian digits into 0-9', () {
    expect(asciiDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(asciiDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    expect(asciiDigits('ص ٢٠ و 5'), 'ص 20 و 5');
  });

  test('the formatter keeps digits only and reads Arabic digits as numbers', () {
    const f = DigitsOnlyFormatter();
    const old = TextEditingValue.empty;
    expect(f.formatEditUpdate(old, typed('٢٠')).text, '20');
    expect(f.formatEditUpdate(old, typed('a٣b4')).text, '34');
    expect(f.formatEditUpdate(old, typed('604')).text, '604');
    expect(f.formatEditUpdate(old, typed('-.,')).text, '');
  });

  test('the cursor stays after what was typed', () {
    const f = DigitsOnlyFormatter();
    final v = f.formatEditUpdate(typed('1'), const TextEditingValue(text: '1٢', selection: TextSelection.collapsed(offset: 2)));
    expect((v.text, v.selection.baseOffset), ('12', 2));
  });
}
