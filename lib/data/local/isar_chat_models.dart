import 'package:isar/isar.dart';

part 'isar_chat_models.g.dart';

/// Lưu tin nhắn local bằng Isar để mở chat là có dữ liệu ngay
@collection
class LocalChatMessage {
  Id id = Isar.autoIncrement;

  /// id thật của message trên server
  @Index(unique: true, replace: true)
  late String messageId;

  /// id cuộc trò chuyện trên server (nếu đã biết)
  @Index()
  String? conversationId;

  /// để phân biệt từng cặp chat, ví dụ myId + targetUserId
  @Index()
  late String myId;

  @Index()
  late String targetUserId;

  late String senderType;
  late String text;

  /// MessageType.name (text, image, video,...)
  @Index()
  late String type;

  @Index()
  late DateTime dateTime;

  late bool isRead;
}
