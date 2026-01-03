import 'dart:convert';
import 'package:socialnetwork/data/server/ServerConfig.dart';
import 'package:http/http.dart' as http;

import '../../repositories/services/FcmService.dart';

class AuthApi {
  static Future<Map<String, dynamic>> checkEmail(String email) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/users/register/checkEmail');
    try {
      final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email})
      );
      if (res.statusCode == 200) {
        final newData = jsonDecode(res.body);
        if (newData['status']) {
          return {
            'status': 'Email đã được đăng ký'
          };
        } else {
          return {
            'status': 'Email chưa được đăng ký'
          };
        }
      } else {
        return {
          'status': 'Lỗi hệ thống'
        };
      }
    } catch (e) {
      print(e);
      return {
        'status': 'Lỗi hệ thống'
      };
    }
  }
  static Future<void> updateFcmToken(String id, String token) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/users/updateToken');
    try{
      await http.post(
          url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id':id,
          'token': token
        })
      );
    }catch(e){
      print('Co loi trong luc update token: $e');
    }
  }
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/users/login');
    try {
      final token = await FcmService.getCurrentToken();
      final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'fcmToken': token
          })
      );
      if(res.statusCode == 200){
        final newData = jsonDecode(res.body);
        return newData;
      }else{
        final newData = jsonDecode(res.body);
        return newData;
      }
    }catch(e){
      print(e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/users/register');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (res.statusCode == 200) {
        final newData = jsonDecode(res.body);
        return {
          'success': true,
          'newData': newData,
        };
      } else {
        return {
          'success': false,
          'error': 'Server error ${res.statusCode}: ${res.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
