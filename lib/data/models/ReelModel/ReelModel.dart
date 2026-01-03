class ReelModel {
  final String reelId;
  final String userId;
  final String content;
  final String visibility;
  final String urlReel;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final int sharesCount;
  final int repostCount;

  ReelModel({
    required this.reelId,
    required this.userId,
    required this.content,
    required this.visibility,
    required this.urlReel,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.sharesCount,
    required this.repostCount,
  });

  // Convert model → JSON
  Map<String, dynamic> toJson() {
    return {
      "reelId": reelId,
      "userId": userId,
      "content": content,
      "visibility": visibility,
      "urlReel": urlReel,
      "createdAt": createdAt.toIso8601String(),
      "likeCount": likeCount,
      "commentCount": commentCount,
      "sharesCount": sharesCount,
      "repostCount": repostCount
    };
  }

  // Convert JSON → model
  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      reelId: json["reelId"],
      userId: json["userId"],
      content: json["content"],
      visibility: json["visibility"],
      urlReel: json["urlReel"],
      createdAt: DateTime.parse(json["createdAt"]),
      likeCount: json["likeCount"] ?? 0,
      commentCount: json["commentCount"] ?? 0,
      sharesCount: json["sharesCount"] ?? 0,
        repostCount: json["repostCount"] ?? 0
    );
  }
}
