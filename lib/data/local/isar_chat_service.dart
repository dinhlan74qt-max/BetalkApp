import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_chat_models.dart';

/// Service chung để mở DB Isar và thao tác với cache tin nhắn
class IsarChatService {
  static final IsarChatService _instance = IsarChatService._internal();
  factory IsarChatService() => _instance;
  IsarChatService._internal();

  Isar? _isar;

  Future<Isar> _getDb() async {
    if (_isar != null) return _isar!;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [LocalChatMessageSchema],
      directory: dir.path,
      inspector: false,
    );
    return _isar!;
  }

  /// Lấy toàn bộ tin nhắn đã cache cho 1 cuộc chat (myId + targetUserId)
  Future<List<LocalChatMessage>> getMessagesForChat(
    String myId,
    String targetUserId,
  ) async {
    final isar = await _getDb();
    return isar.localChatMessages
        .where()
        .filter()
        .myIdEqualTo(myId)
        .and()
        .targetUserIdEqualTo(targetUserId)
        .sortByDateTimeDesc()
        .findAll();
  }

  /// Lưu / cập nhật 1 list tin nhắn vào cache
  Future<void> saveMessagesForChat(
    String myId,
    String targetUserId,
    List<LocalChatMessage> messages,
  ) async {
    final isar = await _getDb();
    await isar.writeTxn(() async {
      for (final msg in messages) {
        msg.myId = myId;
        msg.targetUserId = targetUserId;
        await isar.localChatMessages.putByMessageId(msg);
      }
    });
  }
}
