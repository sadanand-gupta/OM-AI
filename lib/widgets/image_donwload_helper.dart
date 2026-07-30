import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ImageDownloadHelper {
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt < 30) {
        // Android 10 and below - shows a popup
        final status = await Permission.storage.request();
        return status.isGranted;
      } else {
        // Android 11+ doesn't need permission for app-created files in Download
        // But if we need broad access, we must use manageExternalStorage
        return true;
      }
    }
    return true;
  }

  static Future<String?> _saveFileToDownloads({
    required Uint8List bytes,
    required String fileNameWithExtension,
  }) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        debugPrint("❌ Storage permission denied");
        return null;
      }

      if (Platform.isAndroid) {
        // Use external storage directory which is accessible
        final directory = await getExternalStorageDirectory();

        if (directory == null) {
          debugPrint("❌ Could not get external storage directory");
          return null;
        }

        // Navigate up from app-specific folder to public Download folder
        // Path is like: /storage/emulated/0/Android/data/com.example.om_ai/files
        // We want: /storage/emulated/0/Download
        final String downloadPath =
            directory.path.split('Android')[0] + 'Download';
        final downloadDir = Directory(downloadPath);

        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        final filePath = '$downloadPath/$fileNameWithExtension';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        debugPrint('✅ File saved at: $filePath');
        return filePath;
      } else {
        // iOS handling
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileNameWithExtension';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      }
    } catch (e) {
      debugPrint("❌ Error saving file: $e");
      return null;
    }
  }

  static Future<String?> downloadCSV({
    required Uint8List bytes,
    required String fileName,
  }) async {
    return await _saveFileToDownloads(
      bytes: bytes,
      fileNameWithExtension: '$fileName.csv',
    );
  }

  static Future<String?> downloadImage(Uint8List bytes) async {
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
    return await _saveFileToDownloads(
      bytes: bytes,
      fileNameWithExtension: fileName,
    );
  }
}
