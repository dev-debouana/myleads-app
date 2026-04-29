import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Thrown when the selected image exceeds the 5 MB upload limit.
class PhotoFileTooLargeException implements Exception {
  const PhotoFileTooLargeException();
}

/// Manages persistent photo storage for profile and contact images.
///
/// Photos are copied into the app's private documents directory under a
/// hidden `.images/` folder so they survive app updates and are not
/// visible in the system gallery. Two sub-directories are maintained:
///   - `.images/profile_pictures/`  — user profile photos
///   - `.images/contact_pictures/`  — contact photos
///
/// Every image is stored under a random 10-character alphanumeric name
/// with a `.jpg` extension regardless of the original format. Files
/// larger than 5 MB throw [PhotoFileTooLargeException] before any I/O.
///
/// All other errors fall back to the original [sourcePath] so callers
/// never have to handle a null path in the happy path.
class PhotoStorageService {
  PhotoStorageService._();

  static const int _maxBytes = 5 * 1024 * 1024; // 5 MB
  static const String _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  // ── Public API ──────────────────────────────────────────────────────────

  /// Copies [sourcePath] into the `profile_pictures` directory.
  ///
  /// Returns the new persistent path, or [sourcePath] if the copy fails.
  /// Returns [sourcePath] unchanged on web (file I/O not available).
  /// Throws [PhotoFileTooLargeException] if the file exceeds 5 MB.
  static Future<String?> saveProfilePhoto(String sourcePath) async {
    if (kIsWeb) return sourcePath;
    return _copyToDir(sourcePath, 'profile_pictures');
  }

  /// Copies [sourcePath] into the `contact_pictures` directory.
  ///
  /// Returns the new persistent path, or [sourcePath] if the copy fails.
  /// Returns [sourcePath] unchanged on web.
  /// Throws [PhotoFileTooLargeException] if the file exceeds 5 MB.
  static Future<String?> saveContactPhoto(String sourcePath) async {
    if (kIsWeb) return sourcePath;
    return _copyToDir(sourcePath, 'contact_pictures');
  }

  // ── Internal ────────────────────────────────────────────────────────────

  static String _randomName() {
    final rng = Random.secure();
    return List.generate(10, (_) => _chars[rng.nextInt(_chars.length)]).join();
  }

  static Future<String?> _copyToDir(
      String sourcePath, String subDir) async {
    try {
      final source = File(sourcePath);
      final size = await source.length();
      if (size > _maxBytes) throw const PhotoFileTooLargeException();

      final appDir = await getApplicationDocumentsDirectory();
      final targetDir =
          Directory(p.join(appDir.path, '.images', subDir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final targetPath = p.join(targetDir.path, '${_randomName()}.jpg');
      await source.copy(targetPath);
      return targetPath;
    } on PhotoFileTooLargeException {
      rethrow;
    } catch (_) {
      // If anything goes wrong (permissions, disk full, etc.) fall back
      // to the original path so the photo still displays.
      return sourcePath;
    }
  }
}
