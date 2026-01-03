import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialnetwork/data/models/StoryModel/DetailsStory.dart';

import '../../models/StoryModel/StoryCloud.dart';

class StoryPrefsService{
  static Future<void> saveStoryCloudList(List<StoryCloud> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('story_cloud_list', jsonEncode(
        list.map((e) => e.toJson()).toList()
    ));
  }

  static Future<List<StoryCloud>> loadStoryCloudList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('story_cloud_list');
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);

    // Convert về List<StoryCloud>
    List<StoryCloud> list = jsonList
        .map((e) => StoryCloud.fromJson(e))
        .toList();

    // Lọc bỏ story đã quá hạn
    DateTime now = DateTime.now();
    List<StoryCloud> filteredList = list.where((storyCloud) {
      final expiredAt = storyCloud.detailsStory.storyModel.expiredAt;
      return expiredAt.isAfter(now); // giữ lại story còn hạn
    }).toList();

    // Nếu có story bị xóa → lưu lại danh sách mới
    if (filteredList.length != list.length) {
      await prefs.setString(
        'story_cloud_list',
        jsonEncode(filteredList.map((e) => e.toJson()).toList()),
      );
    }

    return filteredList;
  }



  static Future<void> syncStoriesFromApi(List<DetailsStory> apiList) async {
    // Load local list
    List<StoryCloud> localList = await StoryPrefsService.loadStoryCloudList();

    // Tạo Set để check nhanh
    final existingIds = localList.map((e) => e.detailsStory.storyModel.idStory).toSet();

    // Duyệt list từ API
    for (final story in apiList) {
      if (!existingIds.contains(story.storyModel.idStory)) {
        // Chưa tồn tại → thêm mới
        localList.add(
          StoryCloud(
            detailsStory: story,
            isRead: false,
          ),
        );
      }
    }

    // Lưu lại local
    await StoryPrefsService.saveStoryCloudList(localList);
  }
  static Future<void> editViewedStatus(String storyId) async {
    final list = await StoryPrefsService.loadStoryCloudList();

    for (final item in list) {
      if (item.detailsStory.storyModel.idStory == storyId) {
        if (!item.isRead) item.isRead = true;
        break;
      }
    }

    await StoryPrefsService.saveStoryCloudList(list);
  }

}