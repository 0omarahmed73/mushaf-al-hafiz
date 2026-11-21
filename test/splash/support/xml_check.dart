/// A tiny XML reader for the Android resource files of feature 009: it checks well-formedness (balanced and matching tags, quoted
/// attributes, one root) and returns the elements with their attributes so tests can follow references. `package:xml` is only a
/// transitive dependency of the app, and the brief forbids adding a package.
class XmlElement {
  XmlElement(this.name, this.attributes);

  final String name;
  final Map<String, String> attributes;
  final List<XmlElement> children = [];

  /// The text directly inside the element, trimmed (what a `<item name="x">value</item>` holds).
  String text = '';

  /// This element's descendants called [name], depth first.
  List<XmlElement> descendants(String name) {
    final found = <XmlElement>[];
    void walk(XmlElement e) {
      for (final c in e.children) {
        if (c.name == name) found.add(c);
        walk(c);
      }
    }

    walk(this);
    return found;
  }

  /// Every element of the tree including this one.
  List<XmlElement> get all {
    final found = <XmlElement>[this];
    for (final c in children) {
      found.addAll(c.all);
    }
    return found;
  }
}

final RegExp _name = RegExp(r'[A-Za-z_][\w:.\-]*');
final RegExp _attribute = RegExp(
  r'''\s+([A-Za-z_][\w:.\-]*)\s*=\s*(?:"([^"]*)"|'([^']*)')''',
);

/// Reads [source]; throws a [FormatException] when it is not well formed.
XmlElement parseXml(String source) {
  XmlElement? root;
  final stack = <XmlElement>[];
  var i = 0;
  final text = StringBuffer();

  void flushText() {
    final t = text.toString().trim();
    text.clear();
    if (t.isEmpty) {
      return;
    }
    if (stack.isEmpty) {
      throw FormatException('Text outside the root element', source);
    }
    stack.last.text = '${stack.last.text}$t'.trim();
  }

  while (i < source.length) {
    final c = source[i];
    if (c != '<') {
      text.write(c);
      i++;
      continue;
    }
    if (source.startsWith('<!--', i)) {
      final end = source.indexOf('-->', i + 4);
      if (end < 0) {
        throw FormatException('Unterminated comment', source, i);
      }
      i = end + 3;
      continue;
    }
    if (source.startsWith('<?', i)) {
      final end = source.indexOf('?>', i + 2);
      if (end < 0) {
        throw FormatException('Unterminated declaration', source, i);
      }
      i = end + 2;
      continue;
    }
    flushText();
    if (source.startsWith('</', i)) {
      final m = _name.matchAsPrefix(source, i + 2);
      if (m == null) {
        throw FormatException('Bad closing tag', source, i);
      }
      var j = m.end;
      while (j < source.length && source[j].trim().isEmpty) {
        j++;
      }
      if (j >= source.length || source[j] != '>') {
        throw FormatException('Bad closing tag', source, i);
      }
      if (stack.isEmpty || stack.last.name != m[0]) {
        throw FormatException(
          'Closing tag </${m[0]}> does not match',
          source,
          i,
        );
      }
      stack.removeLast();
      i = j + 1;
      continue;
    }
    final m = _name.matchAsPrefix(source, i + 1);
    if (m == null) {
      throw FormatException('Bad tag', source, i);
    }
    final attributes = <String, String>{};
    var j = m.end;
    while (true) {
      final a = _attribute.matchAsPrefix(source, j);
      if (a == null) break;
      final key = a[1]!;
      if (attributes.containsKey(key)) {
        throw FormatException('Duplicate attribute $key', source, j);
      }
      attributes[key] = a[2] ?? a[3] ?? '';
      j = a.end;
    }
    while (j < source.length && source[j].trim().isEmpty) {
      j++;
    }
    final element = XmlElement(m[0]!, attributes);
    if (stack.isEmpty) {
      if (root != null) {
        throw FormatException('More than one root element', source, i);
      }
      root = element;
    } else {
      stack.last.children.add(element);
    }
    if (source.startsWith('/>', j)) {
      i = j + 2;
    } else if (j < source.length && source[j] == '>') {
      stack.add(element);
      i = j + 1;
    } else {
      throw FormatException('Bad attribute or tag end', source, j);
    }
  }
  flushText();
  if (stack.isNotEmpty) {
    throw FormatException('Unclosed <${stack.last.name}>', source);
  }
  if (root == null) {
    throw FormatException('No root element', source);
  }
  return root;
}
