import 'package:socialnetwork/data/models/userModel.dart';
import 'ReelModel.dart';

class DetailsReelModel {
  final ReelModel reelModel;
  final UserModel userModel;
  final bool isLiked;
  final bool isShared;
  final bool isRePosted;

  DetailsReelModel(
      {required this.reelModel,
        required this.userModel,
        required this.isLiked,
        required this.isShared,
        required this.isRePosted});
  factory DetailsReelModel.fromJson(Map<String, dynamic> json) {
    return DetailsReelModel(
      reelModel: ReelModel.fromJson(json['reelModel']),
      userModel: UserModel.fromJson(json['userModel']),
      isLiked: json['isLiked'],
      isShared: json['isShared'],
      isRePosted: json['isRePosted'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'reelModel': reelModel.toJson(),
      'userModel': userModel.toJson(),
      'isLiked': isLiked,
      'isShared': isShared,
      'isRePosted': isRePosted,
    };
  }
}
