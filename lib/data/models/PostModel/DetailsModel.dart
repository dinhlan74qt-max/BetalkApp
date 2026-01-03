import '../userModel.dart';
import 'ArticleModel.dart';

class DetailsModel {
  final ArticleModel articleModel;
  final UserModel userModel;
  final bool isLiked;
  final bool isShared;
  final bool isRePosted;

  DetailsModel({
    required this.articleModel,
    required this.userModel,
    required this.isLiked,
    required this.isShared,
    required this.isRePosted,
  });

  // ✅ Factory: Tạo đối tượng từ JSON (Map)
  factory DetailsModel.fromJson(Map<String, dynamic> json) {
    return DetailsModel(
      // Chuyển đổi Map thành ArticleModel
      articleModel: ArticleModel.fromJson(
        json['articleModel'] as Map<String, dynamic>,
      ),
      // Chuyển đổi Map thành UserModel
      userModel: UserModel.fromJson(
        json['userModel'] as Map<String, dynamic>,
      ),
      // Lấy trạng thái isLiked
      isLiked: json['isLiked'] as bool? ?? false,
      isShared: json['isShared'] as bool? ?? false,
      isRePosted: json['isRePosted'] as bool? ?? false,
    );
  }

  // ✅ Method: Chuyển đổi đối tượng thành JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      // Gọi toJson() của ArticleModel
      'articleModel': articleModel.toJson(),
      // Gọi toJson() của UserModel
      'userModel': userModel.toJson(),
      'isLiked': isLiked,
      'isShared': isShared,
      'isRePosted': isRePosted,
    };
  }

  // Hàm tiện ích CopyWith (rất hữu ích cho StatefulWidget)
  DetailsModel copyWith({
    ArticleModel? articleModel,
    UserModel? userModel,
    bool? isLiked,
    bool? isShared,
    bool? isRePosted,
  }) {
    return DetailsModel(
      articleModel: articleModel ?? this.articleModel,
      userModel: userModel ?? this.userModel,
      isLiked: isLiked ?? this.isLiked,
      isShared: isShared ?? this.isShared,
      isRePosted: isRePosted ?? this.isRePosted,
    );
  }
}
