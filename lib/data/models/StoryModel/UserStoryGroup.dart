import '../userModel.dart';
import 'StoryCloud.dart';

class UserStoryGroup {
  final UserModel user;
  final List<StoryCloud> stories;

  UserStoryGroup({required this.user, required this.stories});
}
