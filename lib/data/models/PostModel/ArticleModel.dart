import 'MediaItem.dart';

class ArticleModel {
  final String articleID;
  final String userId;
  final String content;
  final String idMusic;
  final String visibility;
  final List<MediaItem> mediaItems;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final int sharesCount;
  final int repostCount;

  ArticleModel({
    required this.articleID,
    required this.userId,
    required this.content,
    required this.idMusic,
    required this.visibility,
    required this.mediaItems,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.sharesCount,
    required this.repostCount
  });

  // Convert Map -> ArticleModel
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      articleID: json['articleID'],
      userId: json['userId'],
      content: json['content'],
      idMusic: json['idMusic'],
      visibility: json['visibility'],
      mediaItems: (json['mediaItems'] as List)
          .map((e) => MediaItem.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
        repostCount: json['repostCount'] ?? 0
    );
  }

  // Convert ArticleModel -> Map
  Map<String, dynamic> toJson() {
    return {
      'articleID': articleID,
      'userId': userId,
      'content': content,
      'idMusic': idMusic,
      'visibility': visibility,
      'mediaItems': mediaItems.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'sharesCount': sharesCount,
      'repostCount': repostCount
    };
  }
}