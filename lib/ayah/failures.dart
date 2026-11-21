import 'dart:io';

enum ShareFailureKind { noSpace, couldNotPrepare, couldNotShare }

/// Why preparing or handing over a file or text failed. The user is told in Arabic what happened and the
/// reader keeps working (spec FR-018); a share the user cancels is not a failure.
class ShareFailure implements Exception {
  const ShareFailure(this.kind, [this.cause]);

  /// Turns any error met while preparing a file into a [ShareFailure]: no room to write the file is
  /// [ShareFailureKind.noSpace], anything else [ShareFailureKind.couldNotPrepare].
  factory ShareFailure.fromError(Object error) {
    if (error is ShareFailure) return error;
    if (error is FileSystemException &&
        error.osError?.errorCode == _noSpaceErrno) {
      return ShareFailure(ShareFailureKind.noSpace, error);
    }
    return ShareFailure(ShareFailureKind.couldNotPrepare, error);
  }

  static const int _noSpaceErrno = 28; // ENOSPC

  final ShareFailureKind kind;
  final Object? cause;

  /// The Arabic message shown to the user (contracts/ui.md).
  String get message => switch (kind) {
    ShareFailureKind.noSpace => 'لا توجد مساحة كافية على الهاتف لتجهيز الملف',
    ShareFailureKind.couldNotPrepare => 'تعذّر تجهيز الملف',
    ShareFailureKind.couldNotShare => 'تعذّرت المشاركة',
  };

  @override
  String toString() =>
      'ShareFailure(${kind.name}${cause == null ? '' : ': $cause'})';
}
