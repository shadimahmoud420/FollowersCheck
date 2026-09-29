/// Result of parsing one or more data-export files.
class ParsedExport {
  const ParsedExport({
    required this.followers,
    required this.following,
    required this.foundFollowersFile,
    required this.foundFollowingFile,
  });

  /// Normalized (lowercase) usernames of accounts that follow the user.
  final Set<String> followers;

  /// Normalized (lowercase) usernames of accounts the user follows.
  final Set<String> following;

  /// Whether at least one followers file was recognized.
  final bool foundFollowersFile;

  /// Whether at least one following file was recognized.
  final bool foundFollowingFile;
}

/// A raw file handed to the parser (from a file picker, a test, ...).
class ExportInputFile {
  const ExportInputFile(this.name, this.bytes);

  final String name;
  final List<int> bytes;
}

enum ExportParseError {
  /// The export was made in HTML format; the user must re-export as JSON.
  htmlFormat,

  /// The ZIP archive could not be opened.
  corruptArchive,

  /// No followers / following data was recognized in the files.
  nothingRecognized,
}

class ExportParseException implements Exception {
  const ExportParseException(this.error, [this.detail]);

  final ExportParseError error;
  final String? detail;

  @override
  String toString() => 'ExportParseException($error${detail == null ? '' : ': $detail'})';
}
