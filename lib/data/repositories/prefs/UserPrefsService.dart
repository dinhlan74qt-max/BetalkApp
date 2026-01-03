import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/userModel.dart';

class UserPrefsService{
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('user_data');
    if (data != null) {
      final json = jsonDecode(data);
      return UserModel.fromJson(json);
    }
    return null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  static Future<void> printUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('user_data');
    if (data != null) {
      print('Dữ liệu người dùng đã lưu: $data');
    } else {
      print('Không có dữ liệu người dùng trong SharedPreferences.');
    }
  }
}