import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/ayah/share_service.dart';

/// A file handed to the share sheet.
class SharedFile {
  const SharedFile(this.path, this.fileName, this.mimeType);

  final String path;
  final String fileName;
  final String mimeType;
}

/// A [ShareService] for tests: records what it was given, answers [outcome], or throws [failure].
class FakeShareService implements ShareService {
  final List<String> texts = [];
  final List<SharedFile> files = [];
  ShareOutcome outcome = ShareOutcome.shared;
  ShareFailure? failure;

  @override
  Future<ShareOutcome> shareText(String text) async {
    if (failure != null) throw failure!;
    texts.add(text);
    return outcome;
  }

  @override
  Future<ShareOutcome> shareFile({
    required String path,
    required String fileName,
    required String mimeType,
  }) async {
    if (failure != null) throw failure!;
    files.add(SharedFile(path, fileName, mimeType));
    return outcome;
  }
}
