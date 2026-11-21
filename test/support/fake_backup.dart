import 'package:mushaf/backup/backup.dart';

/// A share sheet and file picker that record and answer instead of opening anything.
class FakeBackupFiles implements BackupFiles {
  final List<({String fileName, String json})> shared = [];

  /// What the picker "picks"; null means the user cancels.
  String? toPick;
  Object? pickError;
  int picks = 0;

  @override
  Future<void> share({required String fileName, required String json}) async {
    shared.add((fileName: fileName, json: json));
  }

  @override
  Future<String?> pick() async {
    picks++;
    final error = pickError;
    if (error != null) throw error;
    return toPick;
  }
}
