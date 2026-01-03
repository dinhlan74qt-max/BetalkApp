import 'package:socialnetwork/data/models/StoryModel/DetailsStory.dart';

class StoryCloud {
  final DetailsStory detailsStory;
  bool isRead;

  StoryCloud({required this.detailsStory, required this.isRead});

  factory StoryCloud.fromJson(Map<String, dynamic> json) {
    return StoryCloud(
      detailsStory: DetailsStory.fromJson(json['detailsStory']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detailsStory': detailsStory.toJson(),
      'isRead': isRead,
    };
  }
}

