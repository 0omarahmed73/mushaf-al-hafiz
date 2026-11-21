import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup.dart';

/// [BackupFiles] on the phone: the Android share sheet and the system file picker.
class PlatformBackupFiles implements BackupFiles {
  /// A backup is a few kilobytes; anything much larger is not one.
  static const int _maxBytes = 20 * 1024 * 1024;

  @override
  Future<void> share({required String fileName, required String json}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: fileName,
      ),
    );
  }

  @override
  Future<String?> pick() async {
    final picked = await FilePicker.pickFile();
    if (picked == null) return null;
    final size = await picked.length();
    if (size != null && size > _maxBytes) {
      throw const FormatException('the file is too large to be a backup');
    }
    return utf8.decode(await picked.readAsBytes());
  }
}
