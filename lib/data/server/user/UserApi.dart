  import 'dart:convert';

  import 'package:socialnetwork/data/models/PostModel/ArticleModel.dart';
import 'package:socialnetwork/data/models/PostModel/RepostModel.dart';
import 'package:socialnetwork/data/models/ReelModel/ReelModel.dart';
import 'package:socialnetwork/data/models/userModel.dart';
  import 'package:socialnetwork/data/repositories/prefs/UserPrefsService.dart';

  import '../ServerConfig.dart';
  import 'package:http/http.dart' as http;

  class UserApi{
    static Future<UserModel?> getUserById(String userId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/?userId=$userId');
      try {
        final res = await http.get(url);
        if (res.statusCode == 200) {
          final newData = jsonDecode(res.body);
          if (newData['success']) {
            final user = UserModel.fromJson(newData['user']);
            return user;
          } else {
            print(newData['error']);
            return null;
          }
        }
      }catch(e){
        print(e);
      }
      return null;
    }
    static Future<void> refreshUserFromServer(String id) async{
      try {
        final user = await UserApi.getUserById(id);
        if (user != null) {
          await UserPrefsService.saveUser(user);
        }
      }catch(e){
        print(e);
      }
    }
    static Future<Map<String, dynamic>> searchUsers(String query) async {
      final url = Uri.parse('${ServerConfig.baseUrl}/user/search?q=$query');
      try {
        final res = await http.get(
          url,
          headers: {'Content-Type': 'application/json'},
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return {
            'success': true,
            'data': data, // Server sẽ trả về một List<Map>
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
          'error': 'Lỗi kết nối: ${e.toString()}',
        };
      }
    }

    static Future<Map<String,dynamic>> followUser(String currentUserId, String targetUserId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/follow');
      try{
        final res = await http.post(
            url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'currentUserId':currentUserId,
            'targetUserId': targetUserId
          })
        );
        if(res.statusCode == 200){
          final data = jsonDecode(res.body);
          return {
            'success': data['success'],
          };
        }else{
          return{
            'success': false,
            'error': 'Server error ${res.statusCode}: ${res.body}'
          };
        }
      }catch(e){
        print(e.toString());
        return{
          'success': false,
          'error': e.toString()
        };
      }
    }

    static Future<Map<String,dynamic>> unFollowUser(String currentUserId, String targetUserId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/unFollow');
      try{
        final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'currentUserId':currentUserId,
              'targetUserId': targetUserId
            })
        );
        if(res.statusCode == 200){
          final data = jsonDecode(res.body);
          return {
            'success': data['success'],
          };
        }else{
          return{
            'success': false,
            'error': 'Server error ${res.statusCode}: ${res.body}'
          };
        }
      }catch(e){
        print(e.toString());
        return{
          'success': false,
          'error': e.toString()
        };
      }
    }

    static Future<Map<String,dynamic>> checkFollow(String currentUserId, String targetUserId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/checkFollow');
      try{
        final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'currentUserId':currentUserId,
              'targetUserId': targetUserId
            })
        );
        if(res.statusCode == 200){
          final data = jsonDecode(res.body);
          return {
            'success': true,
            'status': data['status']
          };
        }else{
          return{
            'success': false,
            'error': 'Server error ${res.statusCode}: ${res.body}'
          };
        }
      }catch(e){
        print(e);
        return{
          'success': false,
          'error': e.toString()
        };
      }
    }

    static Future<List<UserModel>> getFollowing(String userId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/$userId/followings');
      try{
        final res = await http.get(url,);
        if(res.statusCode == 200){
          final data = jsonDecode(res.body);
          final List list = data['data'] ?? [];
          return list.map((e) => UserModel.fromJson(e)).toList();
        }else{
          return [];
        }
      }catch(e){
        print(e.toString());
        return [];
      }
    }

    static Future<List<UserModel>> getFollowers(String userId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/$userId/followers');
      try{
        final res = await http.get(url,);
        if(res.statusCode == 200){
          final data = jsonDecode(res.body);
          final List list = data['data'] ?? [];
          return list.map((e) => UserModel.fromJson(e)).toList();
        }else{
          return [];
        }
      }catch(e){
        print(e.toString());
        return [];
      }
    }

    static Future<List<ArticleModel>> getPostById(String userId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/$userId/posts');
      try{
        final res = await http.get(url,);
        if(res.statusCode == 200){
          final data = jsonDecode(res.body);
          final List list = data['data'] ?? [];
          return list.map((e) => ArticleModel.fromJson(e)).toList();
        }else{
          return [];
        }
      }catch(e){
        print(e.toString());
        return [];
      }
    }
    static Future<List<ReelModel>> getReelById(String userId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/$userId/reels');
      try{
        final res = await http.get(url,);
        if(res.statusCode == 200){
          final data = jsonDecode(res.body);
          final List list = data['data'] ?? [];
          return list.map((e) => ReelModel.fromJson(e)).toList();
        }else{
          return [];
        }
      }catch(e){
        print(e.toString());
        return [];
      }
    }
    static Future<List<RepostModel>> getRepostById(String userId) async{
      final url = Uri.parse('${ServerConfig.baseUrl}/user/$userId/reposts');
      try{
        final res = await http.get(url,);
        if(res.statusCode == 200){
          final data = jsonDecode(res.body);
          final List list = data['data'] ?? [];
          return list.map((e) => RepostModel.fromJson(e)).toList();
        }else{
          return [];
        }
      }catch(e){
        print(e.toString());
        return [];
      }
    }
  }