import 'dart:convert';

import '../ServerConfig.dart';
import 'package:http/http.dart' as http;

class EmailApi{
  static Future<Map<String,dynamic>> sendOtp(String email) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/email/sendOtp');
    try{
      final res = await http.post(
          url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email
        })
      );
      if(res.statusCode == 200){
        final newData = jsonDecode(res.body);
          final otp = newData['otp'];
          return {
            'success': true,
            'otp': otp
          };
      }else{
        return {
          'success': false,
          'error': 'Server Error: ${res.statusCode}: ${res.body}'
        };
      }
    }catch(e){
      print(e.toString());
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}