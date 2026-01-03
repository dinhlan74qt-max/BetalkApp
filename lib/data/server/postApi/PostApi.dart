import 'dart:convert';
import 'dart:io';

import 'package:socialnetwork/data/models/PostModel/ArticleModel.dart';
import 'package:socialnetwork/data/models/PostModel/DetailsComment.dart';
import 'package:socialnetwork/data/models/PostModel/DetailsModel.dart';
import 'package:socialnetwork/data/server/mediaApi/MediaApi.dart';

import '../../models/PostModel/MediaItem.dart';
import '../ServerConfig.dart';
import 'package:http/http.dart' as http;

class PostApi {
  static Future<bool> newPost(String userId, String content, List<File> files, String idMusic, String visibility,) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/post/');
    try {
      final List<MediaItem> list = [];
      for (var file in files) {
        final result = await MediaApi.uploadToServer(file);
        final uploadedUrl = result['url'];
        if (uploadedUrl != null) {
          if (checkMediaType(uploadedUrl) == 'image') {
            final mediaItem = MediaItem(url: uploadedUrl, type: 'image');
            list.add(mediaItem);
          } else if (checkMediaType(uploadedUrl) == 'video') {
            final mediaItem = MediaItem(url: uploadedUrl, type: 'video');
            list.add(mediaItem);
          }
        }
      }
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'content': content == '' ? '0' : content,
          'files': list,
          'idMusic': idMusic,
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
    } catch (e) {
      print(e.toString());
      return false;
    }
  }



  static Future<List<DetailsModel>> getPost(String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/post/feed?userId=$userId');
    try{
      final result = await http.get(url);
      if(result.statusCode == 200){
        final data = jsonDecode(result.body);
        final List<dynamic> list = data['data'];
        return list.map((e) => DetailsModel.fromJson(e)).toList();
      }else{
        return [];
      }
    }catch(e){
      print(e.toString());
      return [];
    }
  }
  static Future<void> likeAndeDislike(String postId, String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/post/$postId/likes');
    try{
      await http.post(url,headers: {'Content-Type': 'application/json'},body: jsonEncode(
          {
            'postId':postId,
            'userId': userId
          }));
    }catch(e){
      print(e.toString());
    }
  }

  static Future<List<DetailsComment>> getComment(String postId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/post/$postId/comments');
    try{
      final result = await http.get(url);
      if(result.statusCode == 200){
        final data = jsonDecode(result.body);
        if(data['success']){
          final List<dynamic> list = data['data'];
          return list.map((e)=> DetailsComment.fromJson(e)).toList();
        }else{
          print(data['error']);
          return [];
        }
      }else{
        print('Loi tu server');
        return [];
      }
    }catch(e){
      print(e.toString());
      return [];
    }
  }
  static Future<bool> comment(String postId, String userId, String content) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/post/$postId/comments');
    try{
      final result = await http.post(url,headers: {'Content-Type': 'application/json'},body: jsonEncode({
        'postId': postId,
        'userId': userId,
        'content': content
      }));
      final data = jsonDecode(result.body);
      return data['success'];
    }catch(e){
      print(e.toString());
      return false;
    }
  }

  static Future<bool> share(String postId, String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/post/$postId/shares');
    try{
      final result = await http.post(url,headers: {'Content-Type': 'application/json'},body: jsonEncode({
        'postId': postId,
        'userId': userId,
      }));
      final data = jsonDecode(result.body);
      return data['success'];
    }catch(e){
      print(e.toString());
      return false;
    }
  }
  static Future<bool> repost(String postId, String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/post/$postId/reposts');
    try{
      final result = await http.post(url,headers: {'Content-Type': 'application/json'},body: jsonEncode({
        'postId': postId,
        'userId': userId,
      }));
      final data = jsonDecode(result.body);
      return data['success'];
    }catch(e){
      print(e.toString());
      return false;
    }
  }

  static String checkMediaType(String url) {
    final ext = url.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return "image";
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return "video";
    if (['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].contains(ext))
      return "audio";

    return "unknown";
  }

  static Future<Map<String,dynamic>> checkInformationPost(String postId,String userId) async{
    final url = Uri.parse('${ServerConfig.baseUrl}/post/check-information-post');
    try{
      final res = await http.post(url,headers: {'Content-Type': 'application/json'},body: jsonEncode({
        'postId': postId,
        'userId': userId,
      }));
      final data = jsonDecode(res.body);
      return {'isLiked': data['isLiked'], 'isShared': data['isShared'], 'isReposted': data['isReposted']};
    }catch(e){
      print(e.toString());
      return {'isLiked': false, 'isShared': false, 'isReposted': false};
    }
  }
}
