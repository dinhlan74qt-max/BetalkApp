import '../ReelModel/ReelModel.dart';
import 'ArticleModel.dart';

class RepostModel {
  final String idRepost;
  final ArticleModel? article;
  final ReelModel? reelModel;
  final String userId;
  final String postId;
  final DateTime createAt;
  final String type;

  RepostModel({
    required this.idRepost,
    required this.article,
    required this.reelModel,
    required this.userId,
    required this.postId,
    required this.createAt,
    required this.type,
  });

  /// Convert Object → JSON
  Map<String, dynamic> toJson() {
    return {
      'idRepost': idRepost,
      'article': article?.toJson(),
      'reelModel': reelModel?.toJson(),
      'userId': userId,
      'postId': postId,
      'createAt': createAt.toIso8601String(),
      'type': type,
    };
  }

  /// Convert JSON → Object
  factory RepostModel.fromJson(Map<String, dynamic> json) {
    return RepostModel(
      idRepost: json['idRepost'],
      article: json['article'] != null
          ? ArticleModel.fromJson(json['article'])
          : null,
      reelModel: json['reelModel'] != null
          ? ReelModel.fromJson(json['reelModel'])
          : null,
      userId: json['userId'],
      postId: json['postId'],
      createAt: DateTime.parse(json['createAt']),
      type: json['type'],
    );
  }
}
