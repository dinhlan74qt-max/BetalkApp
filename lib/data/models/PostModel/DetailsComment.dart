import '../userModel.dart';

class DetailsComment {
  final UserModel user;
  final String content;
  final DateTime createAt;

  DetailsComment({
    required this.user,
    required this.content,
    required this.createAt,
  });

  /// Convert object → JSON Map
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(), // nested object
      'content': content,
      'createAt': createAt.toIso8601String(), // convert datetime to string
    };
  }

  /// Convert JSON Map → object
  factory DetailsComment.fromJson(Map<String, dynamic> json) {
    return DetailsComment(
      user: UserModel.fromJson(json['user']), // convert nested json to model
      content: json['content'] ?? "",
      createAt: DateTime.parse(json['createAt']), // convert string -> DateTime
    );
  }
}
