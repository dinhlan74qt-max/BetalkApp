import 'ChatMessage.dart';

class Conversation {
  final String id;

  // Danh sách người tham gia (User IDs)
  final List<String> participants;

  // Số tin chưa đọc của mỗi user: {"userId": 5}
  final Map<String, int> unreadCounts;

  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  // Background của cuộc trò chuyện (URL ảnh hoặc mã màu)
  final String background;

  // Cấu hình bật/tắt thông báo cho từng user: {"userId": true/false}
  final Map<String, bool> allowNotifications;

  // ✅ Biệt danh có thể null: {"userId": "Biệt danh"}
  final Map<String, String>? nickname;

  Conversation({
    required this.id,
    required this.participants,
    required this.unreadCounts,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.background = '',
    required this.allowNotifications,
    this.nickname,
  });

  // --- Factory: Tạo object từ JSON (Map) ---
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',

      // 1. Parse List<String>
      participants: List<String>.from(json['participants'] ?? []),

      // 2. Parse Map<String, int> (unreadCounts)
      unreadCounts: (json['unreadCounts'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
      ) ??
          {},

      // 3. Parse Nested Object (ChatMessage)
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(Map<String, dynamic>.from(json['lastMessage']))
          : null,

      // 4. Parse DateTime (Sử dụng hàm mới đã sửa)
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      isActive: json['isActive'] ?? true,

      // 5. Parse Background
      background: json['background'] ?? '',

      // 6. Parse Map<String, bool> (allowNotifications)
      allowNotifications:
      (json['allowNotifications'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as bool),
      ) ??
          {},

      // 7. Parse Map<String, String>? (nickname)
      nickname: (json['nickname'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  // --- Method: Chuyển object thành JSON (Map) ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'unreadCounts': unreadCounts,
      'lastMessage': lastMessage?.toJson(),

      // ✅ [SỬA ĐỔI] LƯU DƯỚI DẠNG STRING
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),

      'isActive': isActive,
      'background': background,
      'allowNotifications': allowNotifications,
      'nickname': nickname, // Có thể null
    };
  }

  // --- 🛠️ Hàm phụ trợ parse ngày tháng an toàn (ĐÃ SỬA) ---
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    // ❌ XÓA: Loại bỏ kiểm tra kiểu Timestamp gây lỗi biên dịch
    // if (value is Timestamp) return value.toDate();

    // ✅ Thêm kiểm tra kiểu DateTime (nếu Admin SDK đã tự chuyển đổi)
    if (value is DateTime) return value;

    // ✅ Xử lý String (ISO 8601)
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    // ✅ Xử lý int (Timestamp milliseconds)
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);

    return DateTime.now();
  }

  // --- CÁC HÀM TIỆN ÍCH (HELPER METHODS) ---

  // Lấy biệt danh của một user (nếu không có thì trả về null hoặc tên gốc ở UI)
  String? getNickname(String userId) {
    return nickname?[userId];
  }

  // Kiểm tra xem user có bật thông báo không
  bool isNotificationAllowed(String userId) {
    return allowNotifications[userId] ?? true;
  }

  String getPeerId(String myUserId) {
    return participants.firstWhere(
          (id) => id != myUserId,
      orElse: () => 'Unknown',
    );
  }
}
