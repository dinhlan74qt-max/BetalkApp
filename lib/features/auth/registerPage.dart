import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/core/format/emailFormat.dart';
import 'package:http/http.dart' as http;
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/server/authApi/AuthApi.dart';
import 'package:socialnetwork/features/pages/personalInformation/EmailConfirmation.dart';
import 'dart:convert';
import '../../core/widget/TextBasic.dart';
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passWordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  bool _checkLength = false;
  bool _checkConfirmPassword = false;
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logos/logoUnicon.png',
              ),
              SizedBox(height: 15.h,),
              customText(text: 'Welcome Betalk👋', color: Colors.black, fonSize: 18.sp, fonWeight: FontWeight.bold),
              SizedBox(height: 5.h,),
              customText(text: 'Đăng ký và tận hưởng cộng đồng của chúng tôi', color: Color(0xFFafb0b0), fonSize: 13.sp, fonWeight: FontWeight.normal),
              SizedBox(height: 25.h,),
              _customTextField('Họ và tên', CupertinoIcons.person, fullNameController),
              SizedBox(height: 20.h,),
              _customTextField('Tên người dùng', CupertinoIcons.person, usernameController),
              SizedBox(height: 20.h,),
              _customTextField('Email', Icons.email_outlined, emailController),
              SizedBox(height: 20.h,),
              _buildPasswordField(true),
              if(_checkLength)
              Column(
                children: [
                  SizedBox(height: 10.h,),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        customText(text: 'Mật khẩu ít nhất 6 ký tự', color: Colors.red, fonSize: 12.sp, fonWeight: FontWeight.normal),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 20.h,),
              _buildPasswordField(false),
              if(_checkConfirmPassword)
                Column(
                  children: [
                    SizedBox(height: 10.h,),
                    Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          customText(text: 'Mật khẩu nhập lại không khớp', color: Colors.red, fonSize: 12.sp, fonWeight: FontWeight.normal),
                        ],
                      ),
                    )
                  ],
                ),
              SizedBox(height: 15.h,),
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
                textAlign: TextAlign.center, // 👈 căn giữa khi xuống dòng
              ),
              SizedBox(height: 20.h,),
              SizedBox(
                width: double.infinity,
                child:  ElevatedButton(
                    onPressed: _isLoading ? null : () async{
                      await register();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF5e88fd),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 11.h)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // căn giữa
                      mainAxisSize: MainAxisSize.min, // thu gọn nội dung
                      children: [
                        if (_isLoading) ...[
                          SizedBox(width: 8.w), // khoảng cách giữa chữ và icon
                           SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                        SizedBox(width: 8.w,),
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
              SizedBox(height: 15.h,),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.grey), // chữ xám nhạt
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
      ),),
    );
  }
  Widget _customTextField(String hint, IconData icon,TextEditingController controller){
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
          prefixIcon: Icon(icon,color: const Color(0xFF5e88fd))
      ),
    );
  }
  Widget _buildPasswordField(bool isFirstField) {
    bool obscureText = isFirstField ? _obscurePassword1 : _obscurePassword2;
    return TextField(
      controller: isFirstField ? passWordController : confirmPasswordController,
      obscureText: obscureText,
      onChanged: (value){
        if (isFirstField) {
          setState(() {
            _checkLength = value.length < 6;
          });
        }
        if(!isFirstField){
          setState(() {
            _checkConfirmPassword = passWordController.text != confirmPasswordController.text;
          });
        }
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
        hintText: "********",
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

  Future<void> register() async{
    setState(() {
      _isLoading = true;
    });
    if(usernameController.text.isEmpty || emailController.text.isEmpty || passWordController.text.isEmpty || confirmPasswordController.text.isEmpty){
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.black),
              SizedBox(width: 12.w),
              Text('Vui lòng điền đầy đủ thông tin',style: TextStyle(fontSize: 11.sp,color: Colors.black),),
            ],
          ),
          backgroundColor: Colors.yellow,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    else if(!EmailFormat.checkEmail(emailController.text)){
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.black),
              SizedBox(width: 12.w),
              Text('Định dạng email không đúng',style: TextStyle(fontSize: 11.sp,color: Colors.black),),
            ],
          ),
          backgroundColor: Colors.yellow,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    else if(passWordController.text.length <6){
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.black),
              SizedBox(width: 12.w),
              Text('Mật khẩu ít nhất 6 ký tự',style: TextStyle(fontSize: 11.sp,color: Colors.black),),
            ],
          ),
          backgroundColor: Colors.yellow,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    else if(passWordController.text != confirmPasswordController.text){
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.black),
              SizedBox(width: 12.w),
              Text('Mật khẩu nhập lại không chính xác',style: TextStyle(fontSize: 11.sp,color: Colors.black),),
            ],
          ),
          backgroundColor: Colors.yellow,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    else{
      final resultCheckEmail = await AuthApi.checkEmail( emailController.text.trim());
      if(resultCheckEmail['status'] == 'Email chưa được đăng ký'){
        setState(() {
          _isLoading = false;
        });
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => EmailConfirmation(tempData: {
            'fullName': fullNameController.text,
            'name': usernameController.text,
            'email': emailController.text,
            'password': passWordController.text,
          }),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);  // Bắt đầu bên phải màn hình
            const end = Offset.zero;          // Kết thúc ở vị trí hiện tại
            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.ease);

            return SlideTransition(
              position: tween.animate(curvedAnimation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),  // thời gian chuyển cảnh
        ));
      }else if(resultCheckEmail['status'] == 'Email đã được đăng ký'){
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.black),
                SizedBox(width: 12.w),
                Text('Email đã được đăng ký vui lòng chọn email khác',style: TextStyle(fontSize: 11.sp,color: Colors.black),),
              ],
            ),
            backgroundColor: Colors.yellow,
            duration: Duration(seconds: 2),
          ),
        );
      }else{
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.black),
                SizedBox(width: 12.w),
                Text('Lỗi hệ thống, vui lòng thử lại sau',style: TextStyle(fontSize: 11.sp,color: Colors.black),),
              ],
            ),
            backgroundColor: Colors.yellow,
            duration: Duration(seconds: 2),
          ),
        );
      }

    }
    // try{
      // else{
      //   final result = await AuthApi.register({
      //         'name': usernameController.text,
      //         'email': emailController.text,
      //         'password': passWordController.text,
      //       });
      //   if(result['success']){
      //     // await showSuccessDialog(context);
      //     print('✅ Đăng ký thành công: ${result['data']}');
      //
      //     Navigator.push(context, PageRouteBuilder(
      //       pageBuilder: (context, animation, secondaryAnimation) => EmailConfirmation(tempData: {
      //         'name': usernameController.text,
      //         'email': emailController.text,
      //         'password': passWordController.text,
      //       }),
      //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
      //         const begin = Offset(1.0, 0.0);  // Bắt đầu bên phải màn hình
      //         const end = Offset.zero;          // Kết thúc ở vị trí hiện tại
      //         final tween = Tween(begin: begin, end: end);
      //         final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.ease);
      //
      //         return SlideTransition(
      //           position: tween.animate(curvedAnimation),
      //           child: child,
      //         );
      //       },
      //       transitionDuration: const Duration(milliseconds: 1000),  // thời gian chuyển cảnh
      //     ));
      //
      //   }else{
      //     print('lỗi: ${result['error']}');
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Row(
      //           children: [
      //             Icon(Icons.warning, color: Colors.white),
      //             SizedBox(width: 12),
      //             Text('Hệ thống bận, vui lòng thử lại sau'),
      //           ],
      //         ),
      //         backgroundColor: Colors.red,
      //         duration: Duration(seconds: 2),
      //       ),
      //     );
      //   }
      //   // final url = Uri.parse('http://192.168.1.29:8080/users/register');
      //   // final res = await http.post(
      //   //     url,
      //   //     headers: {'Content-Type': 'application/json'},
      //   //     body: jsonEncode({
      //   //       'name': usernameController.text,
      //   //       'email': emailController.text,
      //   //       'password': passWordController.text,
      //   //     })
      //   // );
      //   // print('Server response: ${res.body}');
      // }
    // }catch(e){
    //   print('lỗi: $e');
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Row(
    //         children: [
    //           Icon(Icons.warning, color: Colors.white),
    //           SizedBox(width: 12),
    //           Text('Hệ thống bận, vui lòng thử lại sau'),
    //         ],
    //       ),
    //       backgroundColor: Colors.red,
    //       duration: Duration(seconds: 2),
    //     ),
    //   );
    //   setState(() {
    //     _isLoading = false;
    //   });
    //   return;
    //
    // }finally{
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }
  }

}
