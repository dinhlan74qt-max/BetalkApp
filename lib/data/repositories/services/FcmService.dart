import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Gọi trong `main()` để lắng nghe token thay đổi
  static void initializeTokenListener(Function(String) onTokenChanged) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      onTokenChanged(newToken); // callback về để bạn gọi API cập nhật
    });
  }

  /// Lấy token hiện tại (dùng khi đăng nhập)
  static Future<String?> getCurrentToken() async {
    return await _messaging.getToken();
  }
}
