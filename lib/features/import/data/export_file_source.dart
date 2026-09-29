import 'package:file_picker/file_picker.dart';

import '../domain/parsed_export.dart';

/// Lets the user choose export files. Abstracted for tests.
abstract interface class ExportFileSource {
  /// Returns the picked files, or an empty list if the user cancelled.
  Future<List<ExportInputFile>> pick();
}

class FilePickerExportFileSource implements ExportFileSource {
  const FilePickerExportFileSource();

  @override
  Future<List<ExportInputFile>> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip', 'json', 'html', 'htm'],
    );
    return [for (final f in files) ExportInputFile(f.name, await f.readAsBytes())];
  }
}
