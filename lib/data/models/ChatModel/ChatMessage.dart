// KHÔNG cần import 'package:firebase_admin/firebase_admin.dart' AS admin nữa
// vì chúng ta không dùng Timestamp.fromDate

enum MessageType {
  text,
  image,
  video,
  audio,
  location,
  file,
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderType;
  final String text;
  final MessageType type;
  final DateTime dateTime;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.text,
    required this.type,
    // SỬA: Dùng DateTime
    required this.dateTime,
    required this.isRead,
  });

  // --- Factory: Tạo object từ JSON (Map) ---
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderType: json['senderType'] ?? '',
      text: json['text'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      // SỬA: Gọi hàm _parseStringOrTimestamp để xử lý dữ liệu đầu vào
      dateTime: _parseStringOrTimestamp(json['dateTime']),
      isRead: json['isRead'] ?? false,
    );
  }

  // --- Method: Chuyển object thành JSON (Map) ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderType': senderType,
      'text': text,
      'type': type.name,

      // SỬA: Chuyển DateTime thành String ISO 8601 để lưu vào Firestore
      // Firestore sẽ lưu nó dưới dạng String, sau này fetch về là String
      'dateTime': dateTime.toIso8601String(),

      'isRead': isRead,
    };
  }

  // --- Hàm phụ trợ để parse ngày tháng an toàn ---
  // Hàm này xử lý các kiểu dữ liệu khác nhau (String, Timestamp, DateTime)
  // mà có thể được fetch về từ Firestore (tùy vào cách bạn lưu trước đó)
  static DateTime _parseStringOrTimestamp(dynamic value) {
    if (value == null) return DateTime.now();

    // 1. Nếu đã là DateTime (do Admin SDK/Database tự động chuyển đổi)
    if (value is DateTime) return value;

    // 2. Nếu là String (dữ liệu được lưu từ phương pháp mới)
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }

    // 3. Nếu là int (timestamp milliseconds)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    // Bỏ qua kiểm tra kiểu Timestamp vì nó gây lỗi biên dịch và không cần thiết
    // vì nếu fetch về, nó sẽ là DateTime hoặc String.

    return DateTime.now();
  }

  // --- CopyWith ---
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderType,
    String? text,
    MessageType? type,
    DateTime? dateTime,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderType: senderType ?? this.senderType,
      text: text ?? this.text,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      isRead: isRead ?? this.isRead,
    );
  }
}
