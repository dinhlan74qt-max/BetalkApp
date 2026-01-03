class UserModel {
  final String id;

  final String userName;
  final String fullName;
  final String email;
  final String dateOfBirth;
  final String gender;

  final String avatarUrl;
  final String bio;

  final int followersCount;
  final int followingCount;
  final int postsCount;

  final String createdAt;
  final bool isOnline;
  final String lastActive;

  final String token;

  UserModel({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.avatarUrl,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.createdAt,
    required this.isOnline,
    required this.lastActive,
    required this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'fullName': fullName,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': createdAt,
      'isOnline': isOnline,
      'lastActive': lastActive,
      'token': token,
    };
  }

  /// 🧠 Convert JSON → model
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      bio: json['bio'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      isOnline: json['isOnline'] ?? false,
      lastActive: json['lastActive'] ?? '',
      token: json['token'] ?? '',
    );
  }
}
