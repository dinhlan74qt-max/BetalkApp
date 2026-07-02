import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/core/format/emailFormat.dart';
import 'package:socialnetwork/core/widget/TextBasic.dart';
import 'package:socialnetwork/features/auth/di/auth_dependencies.dart';
import 'package:socialnetwork/features/pages/personalInformation/EmailConfirmation.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passWordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  bool _checkLength = false;
  bool _checkConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passWordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.black),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 11.sp, color: Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.yellow,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> register() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passWordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin');
      return;
    }

    if (!EmailFormat.checkEmail(email)) {
      _showSnackBar('Định dạng email không đúng');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Mật khẩu ít nhất 6 ký tự');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Mật khẩu nhập lại không chính xác');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resultCheckEmail = await AuthDependencies.checkEmail(email);

      if (!mounted) return;

      if (resultCheckEmail.isAvailable) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                EmailConfirmation(
              tempData: {
                'fullName': fullName,
                'name': username,
                'email': email,
                'password': password,
              },
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              final tween = Tween(begin: begin, end: Offset.zero);
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
        return;
      }

      _showSnackBar(resultCheckEmail.message);
    } catch (_) {
      if (mounted) {
        _showSnackBar('Lỗi hệ thống, vui lòng thử lại sau');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _customTextField(
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        filled: true,
        fillColor: Colors.grey.shade100,
        prefixIcon: Icon(icon, color: const Color(0xFF5e88fd)),
      ),
    );
  }

  Widget _buildPasswordField(bool isFirstField) {
    final obscureText = isFirstField ? _obscurePassword1 : _obscurePassword2;
    final controller =
        isFirstField ? passWordController : confirmPasswordController;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: (value) {
        setState(() {
          if (isFirstField) {
            _checkLength = value.length < 6;
          } else {
            _checkConfirmPassword =
                passWordController.text != confirmPasswordController.text;
          }
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF5e88fd)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              if (isFirstField) {
                _obscurePassword1 = !_obscurePassword1;
              } else {
                _obscurePassword2 = !_obscurePassword2;
              }
            });
          },
        ),
        hintText: '********',
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.r),
          borderSide: BorderSide.none,
        ),
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
                Image.asset('assets/logos/logoUnicon.png'),
                SizedBox(height: 15.h),
                customText(
                  text: 'Welcome Betalk👋',
                  color: Colors.black,
                  fonSize: 18.sp,
                  fonWeight: FontWeight.bold,
                ),
                SizedBox(height: 5.h),
                customText(
                  text: 'Đăng ký và tận hưởng cộng đồng của chúng tôi',
                  color: const Color(0xFFafb0b0),
                  fonSize: 13.sp,
                  fonWeight: FontWeight.normal,
                ),
                SizedBox(height: 25.h),
                _customTextField(
                  'Họ và tên',
                  CupertinoIcons.person,
                  fullNameController,
                ),
                SizedBox(height: 20.h),
                _customTextField(
                  'Tên người dùng',
                  CupertinoIcons.person,
                  usernameController,
                ),
                SizedBox(height: 20.h),
                _customTextField('Email', Icons.email_outlined, emailController),
                SizedBox(height: 20.h),
                _buildPasswordField(true),
                if (_checkLength)
                  Padding(
                    padding: EdgeInsets.only(left: 8.w, top: 10.h),
                    child: Row(
                      children: [
                        customText(
                          text: 'Mật khẩu ít nhất 6 ký tự',
                          color: Colors.red,
                          fonSize: 12.sp,
                          fonWeight: FontWeight.normal,
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 20.h),
                _buildPasswordField(false),
                if (_checkConfirmPassword)
                  Padding(
                    padding: EdgeInsets.only(left: 8.w, top: 10.h),
                    child: Row(
                      children: [
                        customText(
                          text: 'Mật khẩu nhập lại không khớp',
                          color: Colors.red,
                          fonSize: 12.sp,
                          fonWeight: FontWeight.normal,
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 15.h),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    children: const [
                      TextSpan(text: 'Bằng cách tiếp tục, bạn đồng ý với '),
                      TextSpan(
                        text: 'Điều khoản dịch vụ ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(text: 'và '),
                      TextSpan(
                        text: 'Chính sách bảo mật của chúng tôi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5e88fd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
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
                          text: 'Đăng ký',
                          color: Colors.white,
                          fonSize: 16.sp,
                          fonWeight: FontWeight.normal,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    children: [
                      const TextSpan(text: 'Bạn đã có tài khoản? '),
                      TextSpan(
                        text: 'Đăng nhập',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5e88fd),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pop(context);
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
