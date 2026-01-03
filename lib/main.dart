import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialnetwork/core/widget/Main_bottom_nav.dart';
import 'package:socialnetwork/data/repositories/prefs/UserPrefsService.dart';
import 'package:socialnetwork/data/repositories/services/connectivity_service.dart';
import 'package:socialnetwork/data/server/WebSocketService.dart';
import 'package:socialnetwork/data/server/authApi/AuthApi.dart';
import 'package:socialnetwork/data/server/user/UserApi.dart';
import 'package:socialnetwork/features/auth/loginPage.dart';
import 'package:socialnetwork/features/pages/home/newte.dart';
import 'package:socialnetwork/features/pages/message/ChatListPage.dart'; // Import ChatListPage
import 'data/repositories/services/FcmService.dart';
import 'features/pages/home/HomePage.dart';
import 'features/pages/profile/ProfilePage.dart';
import 'features/pages/profile/test.dart';
import 'package:app_links/app_links.dart';
import 'package:socialnetwork/features/pages/search/UserPage.dart';
import 'dart:async';

// ✅ [MỚI] Global Key cho Navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🔥 Background message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final AndroidNotificationChannel chatChannel = const AndroidNotificationChannel(
  'chat-app-d84bc', // Giống channel bên server gửi
  'Chat Messages',
  description: 'Channel dành cho tin nhắn',
  importance: Importance.high,
);

// ✅ [MỚI] Hàm xử lý tin nhắn khi App đang ở Foreground
void _firebaseForegroundHandler(RemoteMessage message) {
  print("💬 Foreground message received: ${message.notification?.title}");

  final notification = message.notification;
  final android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chatChannel.id,
          chatChannel.name,
          channelDescription: chatChannel.description,
          icon: android.smallIcon,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = MethodChannel("app/deeplink");

  platform.setMethodCallHandler((call) async {
    if (call.method == "openProfile") {
      final userId = call.arguments;

      // Nếu app đã có Navigator key -> chuyển đến trang cá nhân
      if (navigatorKey.currentState != null) {
        _navigateToUserProfile(userId);
      }
    }
  });

  // ✅ Khởi tạo xử lý deep link
  _initDeepLinks();

  await dotenv.load(fileName: "env/.env");

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  FirebaseMessaging.onMessage.listen(_firebaseForegroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(chatChannel);
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        final payload = jsonDecode(response.payload!);

        // 1. Lấy ID người dùng từ SharedPreferences (bất đồng bộ)
        final user = await UserPrefsService.getUser();
        final currentUserId = user?.id;

        if (currentUserId != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ChatListPage(myId: currentUserId),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    final tween = Tween(begin: begin, end: end);
                    final curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: Curves.ease,
                    );

                    return SlideTransition(
                      position: tween.animate(curvedAnimation),
                      child: child,
                    );
                  },
              transitionDuration: const Duration(milliseconds: 1000),
            ),
          );
        } else {
          // Nếu không có user ID, chuyển hướng về trang Login
          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }

        print('Notification Tapped with payload: $payload');
      }
    },
  );

  runApp(const MyApp());
}

// ✅ Hàm xử lý deep link
final _appLinks = AppLinks();
StreamSubscription<Uri>? _linkSubscription;

Future<void> _initDeepLinks() async {
  // Xử lý deep link khi app đang chạy
  _linkSubscription = _appLinks.uriLinkStream.listen(
    (Uri uri) {
      _handleDeepLink(uri);
    },
    onError: (err) {
      print('❌ Deep link error: $err');
    },
  );

  // Xử lý deep link khi app được mở từ link (cold start)
  try {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      // Delay một chút để app khởi tạo xong
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleDeepLink(initialUri);
      });
    }
  } catch (e) {
    print('❌ Error getting initial URI: $e');
  }
}

void _handleDeepLink(Uri uri) {
  print('🔗 Deep link received: $uri');
  print('📍 Path segments: ${uri.pathSegments}');
  print('📍 Host: ${uri.host}');
  print('📍 Scheme: ${uri.scheme}');

  try {
    // ✅ Xử lý custom scheme (myapp://post/123 hoặc myapp://user/123)
    if (uri.scheme == 'myapp') {
      final host = uri.host; // 'post' hoặc 'user'
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;

      print('🎯 Custom scheme - Host: $host, ID: $id');

      if (host == 'post' && id != null && id.isNotEmpty) {
        print('✅ Navigating to POST with ID: $id');
        _navigateToPost(id);
        return;
      } else if (host == 'user' && id != null && id.isNotEmpty) {
        print('✅ Navigating to USER profile with ID: $id');
        _navigateToUserProfile(id);
        return;
      }
    }

    // ✅ Xử lý HTTP/HTTPS scheme (http://192.168.1.5:8082/post/123)
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (uri.pathSegments.isEmpty) {
        print('⚠️ Deep link không có path segments');
        return;
      }

      final firstSegment = uri.pathSegments[0];
      print('🎯 HTTP scheme - First segment: $firstSegment');

      // Xử lý route "post"
      if (firstSegment == 'post') {
        final postId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;

        if (postId != null && postId.isNotEmpty) {
          print('✅ Navigating to POST with ID: $postId');
          _navigateToPost(postId);
          return;
        } else {
          print('⚠️ PostId không hợp lệ từ deep link');
        }
      }
      // Xử lý route "user" hoặc "users"
      else if (firstSegment == 'user' || firstSegment == 'users') {
        final userId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;

        if (userId != null && userId.isNotEmpty) {
          print('✅ Navigating to USER profile with ID: $userId');
          _navigateToUserProfile(userId);
          return;
        } else {
          print('⚠️ UserId không hợp lệ từ deep link');
        }
      }
    }

    // Nếu không match bất kỳ pattern nào
    print('⚠️ Deep link không đúng định dạng');
    print('⚠️ Expected: myapp://post/{id}, myapp://user/{id}, http://host/post/{id}, or http://host/user/{id}');
    print('⚠️ Received: $uri');

  } catch (e) {
    print('❌ Lỗi parse deep link: $e');
  }
}

Future<void> _navigateToPost(String postId) async {
  try {
    print('🚀 Starting navigation to post: $postId');

    final currentUser = await UserPrefsService.getUser();
    if (currentUser == null) {
      print('⚠️ Chưa đăng nhập, không thể mở post');
      return;
    }

    print('👤 Current user ID: ${currentUser.id}');

    // Điều hướng đến NewTest với postId
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => NewTest(
          ),
        ),
      );
      print('✅ Đã điều hướng đến Post: $postId');
    } else {
      print('❌ Navigator key is null');
    }
  } catch (e) {
    print('❌ Lỗi khi điều hướng đến Post: $e');
    if (navigatorKey.currentState != null) {
      ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở bài viết: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _navigateToUserProfile(String userId) async {
  try {
    // Lấy thông tin user hiện tại
    final currentUser = await UserPrefsService.getUser();
    if (currentUser == null) {
      return;
    }

    // Lấy thông tin user từ server
    final targetUser = await UserApi.getUserById(userId);
    if (targetUser == null) {
      print('❌ Không tìm thấy user với ID: $userId');
      if (navigatorKey.currentState != null) {
        ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy người dùng'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Điều hướng đến UserPage
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => UserPage(
              myId: currentUser.id,
              userModel: targetUser
          ),
        ),
      );
      print('✅ Đã điều hướng đến profile của: ${targetUser.userName}');
    } else {
      print('❌ Navigator key is null');
    }
  } catch (e) {
    print('❌ Lỗi khi điều hướng đến profile: $e');
    if (navigatorKey.currentState != null) {
      ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở trang cá nhân: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void updateUserId(BuildContext context, String? userId) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?._updateUserId(userId);
  }

  static void startFCMTokenListening(String userId) {
    FcmService.initializeTokenListener((newToken) async {
      await AuthApi.updateFcmToken(userId, newToken);
    });
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await UserPrefsService.getUser();
      final userId = user?.id;

      if (userId != null) {
        MyApp.startFCMTokenListening(userId);
        UserApi.refreshUserFromServer(userId);
      }

      setState(() {
        _userId = userId;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateUserId(String? userId) {
    setState(() {
      _userId = userId;
    });

    if (userId != null) {
      MyApp.startFCMTokenListening(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return WebSocketManager(
      userId: _userId,
      child: ScreenUtilInit(
        designSize: const Size(360, 740),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            // ✅ [SỬA LỖI] Gán Global Key vào MaterialApp
            navigatorKey: navigatorKey,
            locale: const Locale('vi', 'VN'),
            supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            title: 'Betalk',
            theme: ThemeData(primarySwatch: Colors.deepPurple),
            home: ConnectivityWrapper(
              showBanner: false,
              child: _userId == null
                  ? const LoginPage()
                  : const MainNavigationScreen(initialIndex: 0),
            ),
          );
        },
      ),
    );
  }
}

// Widget quản lý vòng đời WebSocket
class WebSocketManager extends StatefulWidget {
  final Widget child;
  final String? userId;

  const WebSocketManager({Key? key, required this.child, this.userId})
    : super(key: key);

  @override
  State<WebSocketManager> createState() => _WebSocketManagerState();
}

class _WebSocketManagerState extends State<WebSocketManager> with WidgetsBindingObserver {
  final _socketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Kết nối nếu có userId
    if (widget.userId != null) {
      _socketService.connect(widget.userId!);
    }
  }

  @override
  void didUpdateWidget(WebSocketManager oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Kết nối khi userId thay đổi
    if (widget.userId != oldWidget.userId) {
      if (widget.userId != null) {
        _socketService.connect(widget.userId!);
      } else {
        _socketService.disconnect();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App vào foreground -> connect lại WebSocket
        if (widget.userId != null) {
          print('📱 App resumed - Connecting WebSocket');
          _socketService.connect(widget.userId!);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        print('📱 App paused/inactive - Disconnecting WebSocket');
        _socketService.disconnect();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
