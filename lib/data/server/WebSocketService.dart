import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';
import 'package:socialnetwork/data/models/ChatModel/Conversation.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _userId;

  bool _isConnecting = false;
  bool _isIntentionalDisconnect = false;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final _reloadController = StreamController<String>.broadcast();
  Stream<String> get reloadUserStream => _reloadController.stream;

  final _conversationController = StreamController<Map<String,dynamic>>.broadcast();
  Stream<Map<String,dynamic>> get conversationStream => _conversationController.stream;

  final _loadMessageController = StreamController<List<ChatMessage>>.broadcast();
  Stream<List<ChatMessage>> get loadMessageStream => _loadMessageController.stream;

  final _conversationsLoadedController = StreamController<List<Conversation>>.broadcast();
  Stream<List<Conversation>> get conversationsLoadedStream => _conversationsLoadedController.stream;

  // ✅ THÊM Stream cho real-time message updates
  final _conversationMessageUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get conversationMessageUpdateStream => _conversationMessageUpdateController.stream;

  // ✅ THÊM MỚI: Stream cho tin nhắn mới
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  // ✅ THÊM MỚI: Stream cho cập nhật conversation
  final _conversationUpdateController = StreamController<Conversation>.broadcast();
  Stream<Conversation> get conversationUpdateStream => _conversationUpdateController.stream;

  // ✅ THÊM MỚI: Stream cho confirm gửi tin nhắn
  final _messageSentController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageSentStream => _messageSentController.stream;

  final _someoneIsOfflineController = StreamController<String>.broadcast();
  Stream<String> get someoneIsOfflineStream => _someoneIsOfflineController.stream;

  final _someoneIsOnlineController = StreamController<String>.broadcast();
  Stream<String> get someoneIsOnlineStream => _someoneIsOnlineController.stream;

  bool get isConnected => _channel != null;
  String? get userId => _userId;

  /// Kết nối WebSocket khi user login
  Future<void> connect(String userId) async {
    if (_isConnecting) {
      print('⏳ Đang kết nối, vui lòng đợi...');
      return;
    }

    _isConnecting = true;

    try {
      _isIntentionalDisconnect = true;
      await disconnect(silent: true);
      _isIntentionalDisconnect = false;

      _userId = userId;

      final wsUrl = dotenv.env['WEBSOCKET_URL'] ?? 'ws://172.20.10.3:8081';
      print('🔌 Đang kết nối WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _channel!.sink.add(jsonEncode({
        'type': 'connect',
        'userId': userId,
      }));

      print('✅ WebSocket connected for user: $userId');
      _connectionController.add(true);
      _reconnectAttempts = 0;

      _signalReload(userId);
      _startPingTimer();

      _channel!.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          _handleMessage(data);
        } catch (e) {
          print('⚠️ Lỗi parse message: $e');
        }
      },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          if (!_isIntentionalDisconnect) {
            print('🔌 WebSocket connection closed (Unexpected)');
            _handleDisconnect();
          } else {
            print('🔌 WebSocket connection closed (Intentional)');
          }
        },
      );
    } catch (e) {
      print('❌ Connect error: $e');
      _handleDisconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _signalReload(String userId) {
    _reloadController.add(userId);
  }

  // Xử lý các message từ server
  void _handleMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'pong':
        break;
      case 'notification':
        print('🔔 Notification: ${data['message']}');
        break;

      case 'user_update':
        if (data['userId'] != null) _signalReload(data['userId']);
        break;

      case 'getOrCreateConversation':
        print('📨 Đã nhận từ server: ${data['type']}');
        if (data['success']) {
          _conversationController.add({
            'success': data['success'],
            'conversation': data['conversation']
          });
        } else {
          _conversationController.add({
            'success': data['success'],
            'error': data['error']
          });
        }
        break;

    // ✅ THÊM MỚI: Nhận tin nhắn mới
      case 'new_message':
        if (data['message'] != null) {
          try {
            final message = ChatMessage.fromJson(data['message']);
            _messageController.add(message);
          } catch (e) {
            print('❌ Lỗi parse message: $e');
          }
        }
        break;

      case 'conversation_updated':
        if (data['conversation'] != null) {
          try {
            final conversation = Conversation.fromJson(data['conversation']);
            _conversationUpdateController.add(conversation);
          } catch (e) {
            print('❌ Lỗi parse conversation: $e');
          }
        }
        break;

      case 'message_sent':
        print('✅ Đã gửi tin nhắn xác nhận từ máy chủ');
        _messageSentController.add({
          'success': data['success'],
          'message': data['message'],
          'error': data['error'],
        });
        break;
      case 'load_message':
        if (data['success'] == true && data['listMessage'] != null) {
          print('✅ Load Message Thành Công');
          try {
            final List<ChatMessage> listMessage = (data['listMessage'] as List)
                .map((msgJson) => ChatMessage.fromJson(msgJson as Map<String, dynamic>))
                .toList();

            _loadMessageController.add(listMessage);
          } catch (e) {
            print('❌ Lỗi parse messages: $e');
          }
        }
        break;
      case 'conversation_message_update':
        if (data['message'] != null) {
          try {
            final message = ChatMessage.fromJson(data['message']);
            _conversationMessageUpdateController.add({
              'conversationId': data['conversationId'],
              'message': message,
            });
          } catch (e) {
            print('❌ Lỗi parse update: $e');
          }
        }
        break;

      case 'subscribed':
        print('✅ Đã subscribe conversation: ${data['conversationId']}');
        break;

      case 'unsubscribed':
        print('❌ Đã unsubscribe conversation: ${data['conversationId']}');
        break;
      case 'conversations_loaded':
        if (data['success'] == true && data['conversations'] != null) {
          try {
            final List<Conversation> conversations = (data['conversations'] as List)
                .map((convoJson) => Conversation.fromJson(convoJson as Map<String, dynamic>))
                .toList();

            _conversationsLoadedController.add(conversations);
          } catch (e) {
            print('❌ Lỗi parse conversations: $e');
          }
        }
        break;
      case 'someone_is_offline':
        try{
          final idOffline = data['idOffline'];
          _someoneIsOfflineController.add(idOffline);
        }catch(e){
          print(e.toString());
        }
        break;
      case 'someone_is_online':
        try{
          final idOnline = data['idOnline'];
          _someoneIsOnlineController.add(idOnline);
        }catch(e){
          print(e.toString());
        }
        break;
      default:
        print('📩 Received: $data');
    }
  }

  // Ngắt kết nối WebSocket
  Future<void> disconnect({bool silent = false}) async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    if (_channel != null) {
      await _channel?.sink.close();
      _channel = null;
    }

    if (!silent) {
      _userId = null;
      _connectionController.add(false);
      print('❌ WebSocket disconnected');
    }
  }

  // Xử lý khi mất kết nối
  void _handleDisconnect() {
    if (_isConnecting || _isIntentionalDisconnect) return;

    _channel = null;
    _connectionController.add(false);
    _pingTimer?.cancel();

    if (_userId != null && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: 3 * _reconnectAttempts);

      print('⏳ Mất kết nối. Thử lại sau ${delay.inSeconds}s (Lần $_reconnectAttempts/$_maxReconnectAttempts)');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        if (_userId != null) {
          print('🔄 Reconnecting...');
          connect(_userId!);
        } else {
          print('⚠️ User đã logout, hủy Reconnect.');
        }
      });
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Đã thử kết nối lại $_maxReconnectAttempts lần nhưng thất bại.');
    }
  }

  // Gửi ping
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null && isConnected) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          print('❌ Lỗi gửi ping: $e');
          timer.cancel();
          _handleDisconnect();
        }
      } else {
        timer.cancel();
      }
    });
  }

  // Gửi message
  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && isConnected) {
      try {
        print('📤 Đã gửi lên server: ${message['type']}');
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('❌ Lỗi gửi message: $e');
      }
    } else {
      print('⚠️ WebSocket chưa kết nối, không thể gửi message');
    }
  }

  void sendOnline(String id) {
    if (_channel != null && isConnected) {
      sendMessage({
        "type": "status",
        "userId": id,
        "online": true,
      });
    }
  }

  void sendOffline() {
    if (_channel != null && isConnected && _userId != null) {
      sendMessage({
        "type": "status",
        "userId": _userId,
        "online": false,
      });
    }
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _reloadController.close();
    _conversationController.close();
    _messageController.close();
    _conversationUpdateController.close();
    _messageSentController.close();
  }
}