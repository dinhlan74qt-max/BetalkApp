import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationManager{
  Future<void> openLocationInMap(String locationString) async {
    try {
      // Parse: "lat,lng?address"
      final parts = locationString.split('?');
      final coords = parts[0].split(',');

      if (coords.length < 2) {
        throw Exception('Định dạng vị trí không hợp lệ');
      }

      final latitude = coords[0].trim();
      final longitude = coords[1].trim();

      // Mở bản đồ tùy theo nền tảng
      final url = Platform.isIOS
          ? 'https://maps.apple.com/?q=$latitude,$longitude'
          : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(parts[1])}';

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Không thể mở bản đồ');
      }
    } catch (e) {
      print('❌ Lỗi mở bản đồ: $e');
    }
  }
}