import 'dart:convert';

import 'package:socialnetwork/data/models/StoryModel/DetailsStory.dart';
import 'package:socialnetwork/data/models/StoryModel/StoryModel.dart';
import 'package:socialnetwork/data/models/userModel.dart';

import '../ServerConfig.dart';
import 'package:http/http.dart' as http;
class StoryApi {
  static Future<Map<String,dynamic>> newStory(String userId,String mediaUrl) async{
    try{
      final url = Uri.parse('${ServerConfig.baseUrl}/story/');
      final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'url': mediaUrl
          })
      );
      if(res.statusCode == 200){
        final newData = jsonDecode(res.body);
        if(newData['success']){
          final story = StoryModel.fromJson(newData['data']);
          return{
            'success': true,
            'data': story
          };
        }else{
          return {
            'success': false,
            'error': newData['error'],
          };
        }
      }else{
        return {
          'success': false,
          'error': 'Server error ${res.statusCode}: ${res.body}',
        };
      }
    }catch(e){
      print(e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }

  }
  static Future<List<DetailsStory>> getStory(String userId) async{
    try{
      final url = Uri.parse('${ServerConfig.baseUrl}/story/?userId=$userId');
      final res = await http.get(url);
      if(res.statusCode ==200){
        final body = res.body;
        final data = jsonDecode(body);
        if(data['success']){
          final List<dynamic> lisData = data['data'];
          final List<DetailsStory> listStory = lisData.map((e) => DetailsStory.fromJson(e)).toList();
          return listStory;
        }else{
          return [];
        }
      }else{
        print('Loi tu server');
        return [];
      }
    }catch(e){
      print(e);
      return [];
    }
  }
  static Future<void> viewedStory(String storyId, String userId) async{
    try{
      final url = Uri.parse('${ServerConfig.baseUrl}/story/$storyId/viewed?userId=$userId');
      await http.post(url,headers: {'Content-Type': 'application/json'},body: jsonEncode({
        'storyId': storyId,
        'userId': userId
      }));
    }catch(e){
      print(e);
    }
  }
  static Future<List<UserModel>> getViewStory(String storyId) async{
    try{
      final url = Uri.parse('${ServerConfig.baseUrl}/story/$storyId/views');
      final res = await http.get(url);
      if(res.statusCode == 200){
        final body = res.body;
        final data = jsonDecode(body);
        final List<dynamic> lisData = data['data'];
        final List<UserModel> listUser = lisData.map((user) => UserModel.fromJson(user)).toList();
        return listUser;
      }else{
        print('Loi tu server');
        return [];
      }
    }catch(e){
      print(e);
      return [];
    }
  }

}