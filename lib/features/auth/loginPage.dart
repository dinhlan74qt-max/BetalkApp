import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialnetwork/core/widget/Main_bottom_nav.dart';
import 'package:socialnetwork/core/widget/TextBasic.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/repositories/prefs/UserPrefsService.dart';
import 'package:socialnetwork/data/server/authApi/AuthApi.dart';
import 'package:socialnetwork/features/auth/registerPage.dart';
import 'package:socialnetwork/features/pages/home/HomePage.dart';
import 'package:socialnetwork/data/server/WebSocketService.dart';
import 'package:socialnetwork/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // Sửa lại thành true để ẩn password mặc định
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate input
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackbar('Vui lòng nhập email');
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showErrorSnackbar('Vui lòng nhập mật khẩu');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthApi.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        print('✅ ${result['message']}');
        print('🎫 Token: ${result['token']}');
        print('👤 User: ${result['user']}');

        final Map<String, dynamic> userMap = result['user'];
        final UserModel userModel = UserModel.fromJson(userMap);

        // Lưu thông tin user
        await UserPrefsService.saveUser(userModel);

        final userId = userModel.id;

        // Kết nối WebSocket
        await WebSocketService().connect(userId);

        // Cập nhật userId trong MyApp
        if (mounted) {
          MyApp.updateUserId(context, userId);

          // Navigate to HomePage
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
              const MainNavigationScreen(initialIndex: 0,),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(
                        begin: const Offset(1.0, 0.0), end: Offset.zero),
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
                (Route<dynamic> route) => false,
          );
        }
      } else {
        // Xử lý lỗi
        String errorMessage = 'Đăng nhập thất bại';

        if (result['error'] != null) {
          errorMessage = result['error'];
        }

        print('❌ $errorMessage');
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      print('❌ Login exception: $e');
      if (mounted) {
        _showErrorSnackbar('Lỗi kết nối. Vui lòng thử lại');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logos/logoUnicon.png',
                ),
                SizedBox(height: 15.h),
                customText(
                    text: 'Welcome Betalk👋',
                    color: Colors.black,
                    fonSize: 18.sp,
                    fonWeight: FontWeight.bold),
                SizedBox(height: 5.h),
                customText(
                    text: 'Nhập email và mật khẩu để đăng nhập',
                    color: const Color(0xFFafb0b0),
                    fonSize: 14.sp,
                    fonWeight: FontWeight.normal),
                SizedBox(height: 25.h),
                TextField(
                  controller: _emailController,
                  style: TextStyle(fontSize: 12.sp),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Color(0xFF5e88fd))),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(fontSize: 12.sp),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 14.h),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: const Icon(CupertinoIcons.lock,
                        color: Color(0xFF5e88fd)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                        onTap: () {
                          // TODO: Navigate to forgot password
                        },
                        child: customText(
                            text: 'Quên mật khẩu?',
                            color: const Color(0xFF5e88fd),
                            fonSize: 12.sp,
                            fonWeight: FontWeight.normal)),
                  ],
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5e88fd),
                          disabledBackgroundColor:
                          const Color(0xFF5e88fd).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 11.h)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading) ...[
                            SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          customText(
                              text: _isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
                              color: Colors.white,
                              fonSize: 16.sp,
                              fonWeight: FontWeight.normal),
                        ],
                      )),
                ),
                SizedBox(height: 15.h),
                Row(
                  children: const [
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                        endIndent: 10,
                      ),
                    ),
                    Text(
                      'hoặc',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey,
                        thickness: 1,
                        indent: 10,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                // button signIn with google
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement Google Sign In
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: const BorderSide(color: Color(0xFFeaedf2)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/google.png',
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Đăng nhập với Google',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    children: [
                      const TextSpan(text: 'Bạn chưa có tài khoản? '),
                      TextSpan(
                        text: 'Đăng ký',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5e88fd),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  const RegisterPage(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(0.0, 1.0);
                                    const end = Offset.zero;
                                    final tween = Tween(begin: begin, end: end);
                                    final curvedAnimation = CurvedAnimation(
                                        parent: animation, curve: Curves.ease);

                                    return SlideTransition(
                                      position: tween.animate(curvedAnimation),
                                      child: child,
                                    );
                                  },
                                  transitionDuration:
                                  const Duration(milliseconds: 800),
                                ));
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}