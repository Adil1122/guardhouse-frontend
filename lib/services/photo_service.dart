import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Take photo using camera
  Future<PhotoResult?> takePhoto() async {
    try {
      debugPrint('Taking photo - kIsWeb: $kIsWeb');
      // Check if running on web
      if (kIsWeb) {
        // For web, use camera with web-specific handling
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (photo == null) {
          return null;
        }

        // For web, we need to handle the file differently
        final File photoFile = File(photo.path);
        final int fileSize = await photoFile.length();
        final DateTime now = DateTime.now();

        return PhotoResult(
          filePath: photo.path,
          fileName: photo.name,
          fileSize: fileSize,
          capturedAt: now,
          latitude: null,
          longitude: null,
        );
      } else {
        // For mobile, use camera with mobile-specific handling
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (photo == null) {
          return null;
        }

        // Get photo metadata
        final File photoFile = File(photo.path);
        final int fileSize = await photoFile.length();
        final DateTime now = DateTime.now();

        return PhotoResult(
          filePath: photo.path,
          fileName: photo.name,
          fileSize: fileSize,
          capturedAt: now,
          latitude: null,
          longitude: null,
        );
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Pick photo from gallery
  Future<PhotoResult?> pickPhotoFromGallery() async {
    try {
      // Check if running on web
      if (kIsWeb) {
        // For web, use gallery with web-specific handling
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (photo == null) {
          return null;
        }

        // For web, we need to handle the file differently
        final File photoFile = File(photo.path);
        final int fileSize = await photoFile.length();
        final DateTime now = DateTime.now();

        return PhotoResult(
          filePath: photo.path,
          fileName: photo.name,
          fileSize: fileSize,
          capturedAt: now,
          latitude: null,
          longitude: null,
        );
      } else {
        // For mobile, use gallery with mobile-specific handling
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (photo == null) {
          return null;
        }

        // Get photo metadata
        final File photoFile = File(photo.path);
        final int fileSize = await photoFile.length();
        final DateTime now = DateTime.now();

        return PhotoResult(
          filePath: photo.path,
          fileName: photo.name,
          fileSize: fileSize,
          capturedAt: now,
          latitude: null,
          longitude: null,
        );
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
      return null;
    }
  }

  /// Add location data to photo result
  PhotoResult addLocationData(PhotoResult photo, double latitude, double longitude) {
    return PhotoResult(
      filePath: photo.filePath,
      fileName: photo.fileName,
      fileSize: photo.fileSize,
      capturedAt: photo.capturedAt,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Get photo as bytes for upload
  Future<Uint8List?> getPhotoBytes(String filePath) async {
    try {
      final File photoFile = File(filePath);
      if (await photoFile.exists()) {
        return await photoFile.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('Error reading photo bytes: $e');
      return null;
    }
  }

  /// Get file size in MB
  double getFileSizeMB(int bytes) {
    return bytes / (1024 * 1024);
  }

  /// Validate photo file
  bool isValidPhoto(String filePath) {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        return false;
      }

      final String extension = filePath.toLowerCase().split('.').last;
      final List<String> validExtensions = ['jpg', 'jpeg', 'png'];
      
      if (!validExtensions.contains(extension)) {
        return false;
      }

      // Check file size (max 5MB)
      final int fileSize = file.lengthSync();
      return fileSize <= 5 * 1024 * 1024; // 5MB
    } catch (e) {
      debugPrint('Error validating photo: $e');
      return false;
    }
  }

  /// Delete temporary photo file
  Future<bool> deletePhoto(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }

  /// Get app's temporary directory for photos
  Future<String> getTempDirectory() async {
    final Directory tempDir = await getTemporaryDirectory();
    final Directory photoDir = Directory('${tempDir.path}/checkin_photos');
    
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    
    return photoDir.path;
  }

  /// Generate unique filename for photo
  String generateUniqueFileName() {
    final DateTime now = DateTime.now();
    final String timestamp = now.millisecondsSinceEpoch.toString();
    return 'checkin_$timestamp.jpg';
  }
}

class PhotoResult {
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;

  PhotoResult({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.capturedAt,
    this.latitude,
    this.longitude,
  });

  /// Get file size in MB
  double get fileSizeMB => fileSize / (1024 * 1024);

  /// Check if photo has location data
  bool get hasLocationData => latitude != null && longitude != null;

  /// Get file size as formatted string
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${fileSizeMB.toStringAsFixed(1)}MB';
    }
  }
}
