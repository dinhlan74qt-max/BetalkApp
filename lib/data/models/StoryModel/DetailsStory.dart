
import '../userModel.dart';
import 'StoryModel.dart';

class DetailsStory {
  final StoryModel storyModel;
  final UserModel? userModel;

  DetailsStory({
    required this.storyModel,
    required this.userModel,
  });

  factory DetailsStory.fromJson(Map<String, dynamic> json) {
    return DetailsStory(
      storyModel: StoryModel.fromJson(json['storyModel']),
      userModel: json['userModel'] != null
          ? UserModel.fromJson(json['userModel'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyModel': storyModel.toJson(),
      'userModel': userModel != null ? userModel!.toJson() : null,
    };
  }
}
