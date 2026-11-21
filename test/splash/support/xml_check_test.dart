import 'package:flutter_test/flutter_test.dart';

import 'xml_check.dart';

void main() {
  test('a vector with a gradient is read', () {
    final root = parseXml('''<?xml version="1.0" encoding="utf-8"?>
<!-- generated -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp" android:viewportWidth="108">
  <path android:pathData="M0 0H108V108H0Z">
    <aapt:attr name="android:fillColor">
      <gradient android:type="linear"><item android:offset="0" android:color="#FF1A212A"/></gradient>
    </aapt:attr>
  </path>
</vector>
''');
    expect(root.name, 'vector');
    expect(root.attributes['android:width'], '108dp');
    expect(root.children.single.name, 'path');
    expect(
      root.descendants('item').single.attributes['android:color'],
      '#FF1A212A',
    );
    expect(root.descendants('aapt:attr'), hasLength(1));
  });

  test('a layer-list and a style file are read', () {
    final list = parseXml(
      '<layer-list xmlns:android="x"><item android:drawable=\'@color/a\'/></layer-list>',
    );
    expect(
      list.descendants('item').single.attributes['android:drawable'],
      '@color/a',
    );
    final style = parseXml(
      '<resources><style name="A" parent="B"><item name="c">@drawable/d</item></style></resources>',
    );
    expect(style.descendants('style').single.attributes['parent'], 'B');
    expect(style.descendants('item').single.text, '@drawable/d');
  });

  test('malformed files are refused', () {
    for (final bad in [
      '<a><b></a>', // mismatched
      '<a><b>', // unclosed
      '<a x=1/>', // unquoted attribute
      '<a/><b/>', // two roots
      '', // nothing
      '<a x="1" x="2"/>', // duplicate attribute
      'text<a/>', // text outside the root
      '<a><!-- open </a>', // unterminated comment
      '<a x="1/>', // unterminated value
    ]) {
      expect(() => parseXml(bad), throwsFormatException, reason: bad);
    }
  });
}
