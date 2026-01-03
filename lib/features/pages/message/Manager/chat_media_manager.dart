// managers/chat_media_manager.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';
import 'package:socialnetwork/data/server/mediaApi/MediaApi.dart';

class ChatMediaManager {
  final BuildContext context;
  final ImagePicker _picker = ImagePicker();

  final Map<String, bool> uploadingMessages = {};
  final Map<String, String> localFilePaths = {};
  final Map<String, String> videoThumbnails = {};

  ChatMediaManager(this.context);

  // ==================== PERMISSION ====================

  Future<bool> requestPhotoPermission() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.photos.request();
        if (status.isDenied) {
          status = await Permission.videos.request();
        }
      } else {
        status = await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      return true;
    }

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
      return false;
    }
    return false;
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidVersion = await DeviceInfoPlugin().androidInfo.then((i) => i.version.sdkInt);

      if (androidVersion >= 33) {
        // Android 13+
        final images = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();

        return images.isGranted || videos.isGranted || audio.isGranted;
      } else {
        // Android < 13
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }

    // iOS không cần
    return true;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) _showPermissionDialog();
    return false;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) _showPermissionDialog();
    return false;
  }

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Vui lòng bật GPS trên thiết bị');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Cần cấp quyền truy cập vị trí');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog();
      return false;
    }

    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần quyền truy cập'),
        content: const Text(
          'Ứng dụng cần quyền truy cập để sử dụng tính năng này. Vui lòng bật quyền trong Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }

  // ==================== PICK MEDIA ====================

  Future<String?> pickLocation() async {
    if (!await requestLocationPermission()) return null;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang lấy vị trí...'),
                ],
              ),
            ),
          ),
        ),
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Get address from coordinates (using geocoding)
      String address = 'Vị trí hiện tại';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Build address string
          List<String> addressParts = [];
          if (place.street != null && place.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }

          address = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Vị trí hiện tại';
        }
      } catch (e) {
        print('⚠️ Không thể lấy địa chỉ: $e');
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      final locationString = '${position.latitude},${position.longitude}?$address';

      print('✅ Location picked: $locationString');
      return locationString;

    } catch (e) {
      // Hide loading
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('❌ Lỗi lấy vị trí: $e');
      _showError('Không thể lấy vị trí: ${e.toString()}');
      return null;
    }
  }

  Future<File?> pickCamera() async {
    if (!await requestCameraPermission()) return null;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      _showError('Lỗi khi chụp ảnh: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> pickMedia() async {
    if (!await requestPhotoPermission()) return null;

    try {
      final XFile? media = await _picker.pickMedia(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (media == null) return null;

      final file = File(media.path);
      final isImage = _isImage(media.path);
      final isVideo = _isVideo(media.path);

      if (!isImage && !isVideo) {
        _showError('Không hỗ trợ định dạng này');
        return null;
      }

      return {
        'file': file,
        'type': isImage ? MessageType.image : MessageType.video,
      };
    } catch (e) {
      _showError('Lỗi khi chọn media: ${e.toString()}');
      return null;
    }
  }

  Future<File?> pickFile() async {
    if (!await requestStoragePermission()) return null;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx',
          'ppt', 'pptx', 'txt', 'zip', 'rar'
        ],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return null;

      final file = File(result.files.single.path!);
      final fileSize = result.files.single.size;

      if (fileSize > 10 * 1024 * 1024) {
        _showError('File quá lớn! Vui lòng chọn file nhỏ hơn 10MB');
        return null;
      }

      return file;
    } catch (e) {
      _showError('Lỗi khi chọn file: ${e.toString()}');
      return null;
    }
  }

  // ==================== VIDEO THUMBNAIL ====================

  Future<void> generateVideoThumbnail(String videoPath, String messageId) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 320,
        maxWidth: 240,
        quality: 70,
        timeMs: 1000,
      );

      if (thumbnail != null) {
        videoThumbnails[messageId] = thumbnail;
        print('✅ Đã tạo thumbnail cho video: $messageId');
      }
    } catch (e) {
      print('⚠️ Không thể tạo thumbnail: $e');
    }
  }

  Future<String?> getNetworkVideoThumbnail(String videoUrl, String messageId) async {
    if (videoThumbnails.containsKey(messageId)) {
      return videoThumbnails[messageId];
    }

    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 320,
        maxWidth: 240,
        quality: 70,
        timeMs: 1000,
      );

      if (thumbnail != null) {
        videoThumbnails[messageId] = thumbnail;
        return thumbnail;
      }
    } catch (e) {
      print('⚠️ Không thể tạo thumbnail từ URL: $e');
    }
    return null;
  }

  // ==================== UPLOAD ====================

  Future<Map<String, dynamic>?> uploadMedia(File file, MessageType type) async {
    try {
      final result = await MediaApi.uploadToServer(file);

      if (type == MessageType.file) {
        return {
          'url': result['url'],
          'fileName': result['fileName'],
          'size': result['size'],
        };
      } else if (type == MessageType.audio) {
        return {
          'url': result['url'],
          'size': result['size'],
        };
      } else {
        return {'url': result['url']};
      }
    } catch (e) {
      _showError('Lỗi upload: ${e.toString()}');
      return null;
    }
  }

  // ==================== HELPERS ====================

  bool _isImage(String path) {
    return path.endsWith(".jpg") ||
        path.endsWith(".jpeg") ||
        path.endsWith(".png") ||
        path.endsWith(".webp");
  }

  bool _isVideo(String path) {
    return path.endsWith(".mp4") ||
        path.endsWith(".mov") ||
        path.endsWith(".avi") ||
        path.endsWith(".mkv") ||
        path.endsWith(".webm") ||
        path.endsWith(".flv") ||
        path.endsWith(".3gp");
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }
}