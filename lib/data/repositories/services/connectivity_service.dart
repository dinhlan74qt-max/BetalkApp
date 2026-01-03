// connectivity_service.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  // Stream để lắng nghe thay đổi kết nối
  final StreamController<bool> _connectionStatusController =
  StreamController<bool>.broadcast();

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Khởi tạo listener
  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      await _updateConnectionStatus(results);
    });

    // Kiểm tra ngay khi khởi động
    checkConnection();
  }

  /// Kiểm tra kết nối internet
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return await _updateConnectionStatus(results);
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  /// Kiểm tra kết nối thực sự (ping Google)
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  /// Cập nhật trạng thái kết nối
  Future<bool> _updateConnectionStatus(List<ConnectivityResult> results) async {
    // Kiểm tra nếu không có kết nối nào hoặc chỉ có none
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _hasConnection = false;
      _connectionStatusController.add(false);
      return false;
    } else {
      // Kiểm tra kết nối thật (không chỉ WiFi/Mobile data bật)
      final hasInternet = await hasInternetConnection();
      _hasConnection = hasInternet;
      _connectionStatusController.add(hasInternet);
      return hasInternet;
    }
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}

// no_internet_widget.dart
class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Không có kết nối Internet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vui lòng kiểm tra kết nối mạng của bạn\nvà thử lại',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry ?? () async {
                  // Không hiện SnackBar ở đây nữa
                  await ConnectivityService().checkConnection();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// no_internet_banner.dart
class NoInternetBanner extends StatelessWidget {
  const NoInternetBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red,
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Không có kết nối Internet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ConnectivityService().checkConnection();
            },
            child: const Text(
              'Thử lại',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// connectivity_wrapper.dart
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool showBanner; // true = hiện banner, false = hiện full screen

  const ConnectivityWrapper({
    Key? key,
    required this.child,
    this.showBanner = false,
  }) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _hasConnection = true;
  bool _isFirstCheck = true;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize();

    // Delay để đảm bảo Scaffold đã được build
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _listenToConnectionChanges();
      }
    });
  }

  void _listenToConnectionChanges() {
    // Lắng nghe thay đổi kết nối
    _connectionSubscription = _connectivityService.connectionStatusStream.listen((hasConnection) {
      if (mounted) {
        final previousState = _hasConnection;

        setState(() {
          _hasConnection = hasConnection;
        });

        // Chỉ hiển thị SnackBar khi có thay đổi (không phải lần đầu tiên)
        if (!_isFirstCheck && previousState != hasConnection) {
          // Hiển thị SnackBar khi có thay đổi (sau khi widget đã build)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            // Chỉ hiện SnackBar khi KHÔNG hiển thị NoInternetWidget
            if (_hasConnection || widget.showBanner) {
              if (!hasConnection) {
                _showNoConnectionSnackBar();
              } else {
                _showConnectionRestoredSnackBar();
              }
            }
          });
        }

        _isFirstCheck = false;
      }
    });
  }

  void _showNoConnectionSnackBar() {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Text('Mất kết nối Internet'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Không làm gì nếu không có Scaffold
    }
  }

  void _showConnectionRestoredSnackBar() {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 12),
              Text('Đã kết nối Internet'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Không làm gì nếu không có Scaffold
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasConnection) {
      if (widget.showBanner) {
        // Hiển thị banner ở trên
        return Column(
          children: [
            const NoInternetBanner(),
            Expanded(child: widget.child),
          ],
        );
      } else {
        // Hiển thị full screen
        return NoInternetWidget(
          onRetry: () async {
            await _connectivityService.checkConnection();
          },
        );
      }
    }

    return widget.child;
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}