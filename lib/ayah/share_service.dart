import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'failures.dart';

/// What happened to a share: the user chose a target, or closed the share sheet (never an error).
enum ShareOutcome { shared, dismissed }

/// Hands text or a file to the phone's share sheet. Tests replace it with a fake.
abstract interface class ShareService {
  /// Throws [ShareFailure] (`couldNotShare`) when the platform call fails.
  Future<ShareOutcome> shareText(String text);

  Future<ShareOutcome> shareFile({
    required String path,
    required String fileName,
    required String mimeType,
  });
}

/// [ShareService] on the phone: the Android share sheet through `share_plus`.
class PlatformShareService implements ShareService {
  PlatformShareService({
    Future<ShareResult> Function(ShareParams params)? share,
  }) : _share = share ?? SharePlus.instance.share;

  final Future<ShareResult> Function(ShareParams params) _share;

  @override
  Future<ShareOutcome> shareText(String text) => _run(ShareParams(text: text));

  @override
  Future<ShareOutcome> shareFile({
    required String path,
    required String fileName,
    required String mimeType,
  }) => _run(
    ShareParams(
      files: [XFile(path, name: fileName, mimeType: mimeType)],
    ),
  );

  Future<ShareOutcome> _run(ShareParams params) async {
    try {
      final result = await _share(params);
      // "unavailable" means the platform cannot tell what the user did; nothing went wrong.
      return result.status == ShareResultStatus.dismissed
          ? ShareOutcome.dismissed
          : ShareOutcome.shared;
    } catch (error) {
      throw ShareFailure(ShareFailureKind.couldNotShare, error);
    }
  }
}

/// The folder `<temp>/share/` where pictures and PDFs are written before they are shared. A file is never
/// deleted right after the share call returns (the receiving app may still be reading it); the folder is
/// emptied when the app starts and before a new job (contracts/share-formats.md).
class TempShareFiles {
  TempShareFiles({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getTemporaryDirectory;

  final Future<Directory> Function() _baseDir;

  Future<Directory> _folder() async =>
      Directory('${(await _baseDir()).path}/share');

  /// An empty file handle named [fileName] in the folder (created if missing); an older file of the same
  /// name is removed.
  Future<File> create(String fileName) async {
    final folder = await _folder();
    await folder.create(recursive: true);
    final file = File('${folder.path}/$fileName');
    if (await file.exists()) await file.delete();
    return file;
  }

  /// Removes everything in the folder; fine when there is no folder yet.
  Future<void> clean() async {
    final folder = await _folder();
    if (!await folder.exists()) return;
    await for (final entry in folder.list()) {
      await entry.delete(recursive: true);
    }
  }
}
