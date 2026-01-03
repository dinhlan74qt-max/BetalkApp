// managers/chat_message_manager.dart
import 'dart:async';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';
import 'package:socialnetwork/data/models/ChatModel/Conversation.dart';
import 'package:socialnetwork/data/server/WebSocketService.dart';
import 'package:socialnetwork/data/local/isar_chat_models.dart';
import 'package:socialnetwork/data/local/isar_chat_service.dart';

class ChatMessageManager {
  final WebSocketService _socketService;
  final String myId;
  final String targetUserId;

  Conversation? conversation;
  List<ChatMessage> messages = [];
  bool isLoadingConversation = true;
  String? errorMessage;

  StreamSubscription? _conversationSub;
  StreamSubscription? _newMessageSub;
  StreamSubscription? _messageSentSub;
  StreamSubscription? _loadMessageSub;
  StreamSubscription? _realtimeUpdateSub;

  final IsarChatService _isarChatService = IsarChatService();

  ChatMessageManager({
    required WebSocketService socketService,
    required this.myId,
    required this.targetUserId,
  }) : _socketService = socketService;

  // Khởi tạo listeners
  void initialize(Function onStateChanged) {
    // 1️⃣ Load tin nhắn từ Isar trước cho cảm giác "mở là có tin luôn"
    _loadLocalMessages(onStateChanged);

    // 2️⃣ Sau đó mới nghe socket & gọi server
    _listenToConversationResponse(onStateChanged);
    _listenToNewMessages(onStateChanged);
    _listenToMessageSent(onStateChanged);
    _listenLoadMessage(onStateChanged);
    _listenToRealtimeUpdates(onStateChanged);
    requestConversation();
  }

  Future<void> _loadLocalMessages(Function onStateChanged) async {
    try {
      final localMessages = await _isarChatService.getMessagesForChat(
        myId,
        targetUserId,
      );
      if (localMessages.isNotEmpty) {
        messages = localMessages
            .map(
              (m) => ChatMessage(
                id: m.messageId,
                conversationId: m.conversationId ?? '',
                senderType: m.senderType,
                text: m.text,
                type: MessageType.values.firstWhere(
                  (e) => e.name == m.type,
                  orElse: () => MessageType.text,
                ),
                dateTime: m.dateTime,
                isRead: m.isRead,
              ),
            )
            .toList();
        isLoadingConversation = false;
        onStateChanged();
        print('📦 Đã load ${messages.length} tin nhắn từ Isar (local cache)');
      }
    } catch (e) {
      print('❌ Lỗi load tin nhắn từ Isar: $e');
    }
  }

  void requestConversation() {
    _socketService.sendMessage({
      'type': 'getOrCreateConversation',
      'userId1': myId,
      'userId2': targetUserId,
    });
    print('✅ Gửi yêu cầu tìm/tạo Conversation qua Socket');
  }

  void requestMarkAsRead() {
    if (conversation == null) return;
    _socketService.sendMessage({
      'type': 'mark_as_read',
      'userId': myId,
      'conversationId': conversation!.id,
    });
  }

  void _listenToConversationResponse(Function onStateChanged) {
    _conversationSub = _socketService.conversationStream.listen((result) {
      if (result['success'] == true) {
        final convoMap = result['conversation'];
        conversation = Conversation.fromJson(convoMap);
        isLoadingConversation = false;
        errorMessage = null;

        print('✅ Conversation ID đã sẵn sàng: ${conversation!.id}');

        loadOldMessages();
        _subscribeToConversation(conversation!.id);

        // Cập nhật lại conversationId cho cache local nếu trước đó mình đã lưu mà chưa có id
        _updateLocalConversationId(conversation!.id);

        requestMarkAsRead();
        onStateChanged();
      } else {
        errorMessage = result['error'] ?? 'Không thể tìm/tạo cuộc trò chuyện.';
        isLoadingConversation = false;
        onStateChanged();
        print('❌ Lỗi từ Server khi tạo chat: $errorMessage');
      }
    });
  }

  void _subscribeToConversation(String conversationId) {
    _socketService.sendMessage({
      'type': 'subscribe_conversation',
      'conversationId': conversationId,
      'userId': myId,
    });
    print('📡 Đã subscribe conversation: $conversationId');
  }

  void _listenToRealtimeUpdates(Function onStateChanged) {
    _realtimeUpdateSub = _socketService.conversationMessageUpdateStream.listen((
      data,
    ) {
      final conversationId = data['conversationId'];
      final message = data['message'] as ChatMessage;

      if (conversationId == conversation?.id) {
        final exists = messages.any((m) => m.id == message.id);
        if (!exists) {
          messages.insert(0, message);
          _saveMessagesToLocal([message]);
          onStateChanged();
        }
      }
    });
  }

  void _listenToNewMessages(Function onStateChanged) {
    _newMessageSub = _socketService.messageStream.listen((message) {
      if (message.conversationId == conversation?.id) {
        final exists = messages.any((m) => m.id == message.id);
        if (!exists) {
          messages.insert(0, message);
          _saveMessagesToLocal([message]);
          onStateChanged();
          print('💬 Received new message: ${message.text}');
        }
      }
    });
  }

  void _listenToMessageSent(Function onStateChanged) {
    _messageSentSub = _socketService.messageSentStream.listen((result) {
      if (result['success'] == true && result['message'] != null) {
        final realMessage = ChatMessage.fromJson(result['message']);

        // ✅ Tìm và XÓA tin nhắn tạm có cùng nội dung
        messages.removeWhere(
          (m) =>
              m.id.startsWith('temp_') &&
              m.text == realMessage.text &&
              m.senderType == realMessage.senderType,
        );

        // ✅ Thêm tin nhắn thật từ server
        final exists = messages.any((m) => m.id == realMessage.id);
        if (!exists) {
          messages.insert(0, realMessage);
        }

        _saveMessagesToLocal([realMessage]);

        onStateChanged();
        print("✅ Replace temp → real: ${realMessage.id}");
      }
    });
  }

  void _listenLoadMessage(Function onStateChanged) {
    _loadMessageSub = _socketService.loadMessageStream.listen((result) {
      messages = result;
      _saveMessagesToLocal(result);
      onStateChanged();
      print('📥 Đã load ${result.length} tin nhắn');
    });
  }

  void loadOldMessages() {
    if (conversation == null) return;
    print('📥 Loading old messages...');
    _socketService.sendMessage({
      'type': 'load_message',
      'conversationId': conversation!.id,
    });
  }

  void sendMessage({
    required MessageType type,
    required String text,
    Function? onStateChanged,
  }) {
    if (conversation == null) return;

    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversation!.id,
      senderType: myId,
      text: text,
      type: type,
      dateTime: DateTime.now(),
      isRead: false,
    );

    // ✅ Insert tin nhắn tạm
    messages.insert(0, tempMessage);
    // Lưu tạm vào local luôn để lần mở sau vẫn thấy (conversationId có thể null)
    _saveMessagesToLocal([tempMessage]);

    // ✅ GỌI CALLBACK ĐỂ UPDATE UI
    onStateChanged?.call();

    // ✅ Gửi qua WebSocket
    _socketService.sendMessage({
      'type': 'send_message',
      'data': {
        'conversationId': conversation!.id,
        'senderType': myId,
        'text': text,
        'type': type.name,
      },
    });

    print('📤 Sent ${type.name}: $text');
  }

  Future<void> _saveMessagesToLocal(List<ChatMessage> list) async {
    try {
      if (list.isEmpty) return;
      final localList = list.map((m) {
        final local = LocalChatMessage()
          ..messageId = m.id
          ..conversationId = (m.conversationId.isEmpty
              ? conversation?.id
              : m.conversationId)
          ..senderType = m.senderType
          ..text = m.text
          ..type = m.type.name
          ..dateTime = m.dateTime
          ..isRead = m.isRead;
        return local;
      }).toList();

      await _isarChatService.saveMessagesForChat(myId, targetUserId, localList);
    } catch (e) {
      print('❌ Lỗi lưu tin nhắn vào Isar: $e');
    }
  }

  Future<void> _updateLocalConversationId(String conversationId) async {
    try {
      final localMessages = await _isarChatService.getMessagesForChat(
        myId,
        targetUserId,
      );
      if (localMessages.isEmpty) return;

      for (final m in localMessages) {
        m.conversationId ??= conversationId;
      }
      await _isarChatService.saveMessagesForChat(
        myId,
        targetUserId,
        localMessages,
      );
    } catch (e) {
      print('❌ Lỗi cập nhật conversationId trong Isar: $e');
    }
  }

  void dispose() {
    if (conversation != null) {
      _socketService.sendMessage({
        'type': 'unsubscribe_conversation',
        'conversationId': conversation!.id,
        'userId': myId,
      });
    }

    _conversationSub?.cancel();
    _newMessageSub?.cancel();
    _messageSentSub?.cancel();
    _realtimeUpdateSub?.cancel();
    _loadMessageSub?.cancel();
  }
}
