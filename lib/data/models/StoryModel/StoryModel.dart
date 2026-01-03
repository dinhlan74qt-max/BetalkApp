import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String idStory;
  final String userId;
  final String url;
  final DateTime createdAt;
  final DateTime expiredAt;
  final int likeCount;
  final int viewCount;

  StoryModel({
    required this.idStory,
    required this.userId,
    required this.url,
    required this.createdAt,
    required this.expiredAt,
    required this.likeCount,
    required this.viewCount,
  });

  // ---------------------------
  // toJson
  // ---------------------------
  Map<String, dynamic> toJson() {
    return {
      'idStory': idStory,
      'userId': userId,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
      'expiredAt': expiredAt.toIso8601String(),
      'likeCount': likeCount,
      'viewCount': viewCount,
    };
  }

  // ---------------------------
  // fromJson (nhận docSnap hoặc Map)
  // ---------------------------
  factory StoryModel.fromJson(dynamic json) {
    return StoryModel(
      idStory: json['idStory'] as String,
      userId: json['userId'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json["createdAt"]),
      expiredAt: DateTime.parse(json["expiredAt"]),
      likeCount: json['likeCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
    );
  }
}
