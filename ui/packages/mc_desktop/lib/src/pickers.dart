import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:mc_artifacts/mc_artifacts.dart';
export 'package:mc_workspaces/mc_workspaces.dart' show chooseWorkspaceDirectory;

Future<String?> chooseGameDirectory(String? initialPath) => getDirectoryPath(
  initialDirectory: initialPath,
  confirmButtonText: 'Choose folder',
  canCreateDirectories: false,
);
Future<String?> chooseExecutable(String? initial) async => (await openFile(
  initialDirectory: initial == null ? null : File(initial).parent.path,
))?.path;
Future<ArchiveFile?> chooseArchive() async {
  final file = await openFile();
  if (file == null) return null;
  return ArchiveFile(file.path, await file.length());
}

Future<bool> saveSupportReport(String fileName, Uint8List content) async {
  final location = await getSaveLocation(suggestedName: fileName);
  if (location == null) return false;
  await XFile.fromData(
    content,
    mimeType: 'application/json',
    name: fileName,
  ).saveTo(location.path);
  return true;
}
