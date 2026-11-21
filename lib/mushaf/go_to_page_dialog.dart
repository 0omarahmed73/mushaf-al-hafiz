import 'package:material_ui/material_ui.dart';

import '../digits.dart';
import 'models.dart';

/// «الانتقال إلى صفحة»: a small popup with a number field. Pops with the typed page (1..604); the reader
/// shows it in browse mode, like a jump from the index.
class GoToPageDialog extends StatefulWidget {
  const GoToPageDialog({super.key, required this.current});

  /// The page being shown, written in the field as its hint.
  final int current;

  @override
  State<GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<GoToPageDialog> {
  final TextEditingController _field = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final page = int.tryParse(asciiDigits(_field.text.trim()));
    if (page == null || page < 1 || page > MushafMeta.pageCount) {
      setState(() => _error = 'أدخل رقماً من 1 إلى 604');
      return;
    }
    Navigator.of(context).pop(page);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('goto-dialog'),
      title: const Text('الانتقال إلى صفحة'),
      content: TextField(
        key: const ValueKey('goto-field'),
        controller: _field,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        inputFormatters: const [DigitsOnlyFormatter()],
        decoration: InputDecoration(
          labelText: 'رقم الصفحة من 1 إلى 604',
          hintText: '${widget.current}',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          key: const ValueKey('goto-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const ValueKey('goto-go'),
          onPressed: _submit,
          child: const Text('اذهب'),
        ),
      ],
    );
  }
}
