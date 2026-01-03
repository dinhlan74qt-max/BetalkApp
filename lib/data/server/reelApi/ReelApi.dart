import 'dart:convert';
import 'dart:io';
import 'package:socialnetwork/data/models/PostModel/DetailsComment.dart';
import 'package:socialnetwork/data/models/ReelModel/DetailsReelModel.dart';
import 'package:socialnetwork/data/server/mediaApi/MediaApi.dart';
import '../ServerConfig.dart';
import 'package:http/http.dart' as http;
class ReelApi {
  static Future<bool> newReel(String userId, String content,File file, String visibility) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/reels/');
    try{
      final result = await MediaApi.uploadToServer(file);
      final uploadedUrl = result['url'];
      if(uploadedUrl != null){
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'content': content == '' ? '0' : content,
            'urlReel': uploadedUrl,
            'visibility': visibility,
          }),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return data['success'];
        } else {
          final data = jsonDecode(res.body);
          print(data['error']);
          return false;
        }
      }else{
        return false;
      }

    }catch (e) {
      print(e.toString());
      return false;
    }
  }


  static Future<List<DetailsReelModel>> getReel(String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/reels/getReel');
    try{
      final res = await http.post(
          url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId':userId
        })
      );
      if(res.statusCode == 200){
        final data = jsonDecode(res.body);
        final List<dynamic> listDynamic = data['data'];
        return listDynamic.map((e) => DetailsReelModel.fromJson(e)).toList();
      }else{
        final data = jsonDecode(res.body);
        print(data['error']);
        return [];
      }
    }catch(e){
      print(e.toString());
      return [];
    }
  }

  static Future<bool> likeReel(String reelId, String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/reels/$reelId/likes');
    try{
      final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId':userId,
            'reelId': reelId
          })
      );
      final data = jsonDecode(res.body);
      return data['success'];
    }catch(e){
      print(e.toString());
      return false;
    }
  }

  static Future<bool> shareReel(String reelId, String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/reels/$reelId/shares');
    try{
      final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId':userId,
            'reelId': reelId
          })
      );
      final data = jsonDecode(res.body);
      return data['success'];
    }catch(e){
      print(e.toString());
      return false;
    }
  }

  static Future<bool> repostReel(String reelId, String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/reels/$reelId/reposts');
    try{
      final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId':userId,
            'reelId': reelId
          })
      );
      final data = jsonDecode(res.body);
      return data['success'];
    }catch(e){
      print(e.toString());
      return false;
    }
  }

  static Future<bool> comment(String userId,String reelId,String content) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/reels/$reelId/comments');
    try{
      final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId':userId,
            'reelId': reelId,
            'content': content
          })
      );
      final data = jsonDecode(res.body);
      return data['success'];
    }catch(e){
      print(e.toString());
      return false;
    }
  }
  static Future<List<DetailsComment>> getComment(String reelId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/reels/$reelId/comments');
    try{
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      final List<dynamic> list = data['data'];
      if(data['success']){
        return list.map((e) => DetailsComment.fromJson(e)).toList();
      }else{
        return [];
      }
    }catch(e){
      print(e.toString());
      return [];
    }
  }
}