import 'dart:io' show File;

import 'package:permission_handler/permission_handler.dart';

class FileManagementService {
  const FileManagementService();

  Future<bool> deleteFile(File file) async {
    try {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted && await file.exists()) {
        await file.delete(recursive: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
