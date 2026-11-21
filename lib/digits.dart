import 'package:flutter/services.dart';

/// [text] with Arabic-Indic (٠–٩) and Persian (۰–۹) digits written as 0–9.
String asciiDigits(String text) {
  final out = StringBuffer();
  for (final r in text.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      out.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      out.writeCharCode(0x30 + r - 0x06F0);
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

final RegExp _notDigit = RegExp(r'[^0-9]');

/// For number fields: keeps only digits and turns Arabic-Indic digits typed on an Arabic keyboard
/// into 0–9, so «٢٠» is read as 20.
class DigitsOnlyFormatter extends TextInputFormatter {
  const DigitsOnlyFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = asciiDigits(newValue.text).replaceAll(_notDigit, '');
    if (text == newValue.text) {
      return newValue;
    }
    final end = newValue.selection.end.clamp(0, newValue.text.length);
    final cursor = asciiDigits(newValue.text.substring(0, end)).replaceAll(_notDigit, '').length;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: cursor));
  }
}
