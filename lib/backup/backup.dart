import 'backup_service.dart';

/// The phone's share sheet and file picker for backups; tests use a fake.
abstract class BackupFiles {
  /// Offers [json] for sharing as a file called [fileName].
  Future<void> share({required String fileName, required String json});

  /// Lets the user pick a backup file and returns its text, or null if they cancel.
  Future<String?> pick();
}

/// The backup pieces the settings screen uses, provided once at the top of the app.
class Backup {
  const Backup({required this.service, required this.files});

  final BackupService service;
  final BackupFiles files;
}
