import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../ServerConfig.dart';

class MediaApi{
  static Future<Map<String,dynamic>> uploadToServer(File imageFile) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/cloudinary/upload');

    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      return jsonData;
    }else{
      return {
        'success': false,
        'error': 'Server error ${response.statusCode}}',
      };
    }
  }

  static Future<Map<String, dynamic>> createVideoFromImageAndAudio(File imageFile, String audioUrl,) async {
    final url = Uri.parse(
        '${ServerConfig.baseUrl}/cloudinary/createVideoFromImageAndAudio');

    final request = http.MultipartRequest('POST', url);

    // Thêm file ảnh
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    // Thêm audioUrl (text field)
    request.fields['audioUrl'] = audioUrl;

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseData);
    } else {
      return {
        'success': false,
        'error':
        'Server error ${response.statusCode}: $responseData',
      };
    }
  }

  static Future<Map<String, dynamic>> createVideoFromImage(File imageFile) async {
    try {
      final uploadResult = await uploadToServer(imageFile);
      if (uploadResult['success'] != true || uploadResult['url'] == null) {
        return {
          'success': false,
          'error': 'Upload ảnh thất bại: ${uploadResult['error']}'
        };
      }

      final imageUrl = uploadResult['url'];
      final url = Uri.parse('${ServerConfig.baseUrl}/cloudinary/createVideoFromImage');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',  // ✅ JSON, không phải multipart!
        },
        body: jsonEncode({
          'imageUrl': imageUrl,
          'durationSeconds': 15,
        }),
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Video created: ${data['videoUrl']}');
        return data;
      } else {
        return {
          'success': false,
          'error': 'Server error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e, stackTrace) {
      print(' $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


}