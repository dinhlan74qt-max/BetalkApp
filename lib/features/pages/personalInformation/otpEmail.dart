import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'Information.dart';

class OtpEmail extends StatefulWidget {
  final String otp;
  final Map<String, dynamic> tempData;
  const OtpEmail({super.key, required this.otp, required this.tempData});

  @override
  State<OtpEmail> createState() => _OtpEmailState();
}

class _OtpEmailState extends State<OtpEmail> {
  String _otp = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nhập mã OTP'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Nhập mã OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vui lòng nhập mã 4 chữ số đã được gửi đến email của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              PinCodeTextField(
                appContext: context,
                length: 4,
                obscureText: false,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12.r),
                  fieldHeight: 60.h,
                  fieldWidth: 60.w,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Color(0xFFEDE9FE),
                  activeColor: Color(0xFFEDEFFB),
                  selectedColor: Color(0xFFEDEFFB),
                  inactiveColor: Colors.grey.shade300,
                ),
                animationDuration: Duration(milliseconds: 100),
                backgroundColor: Colors.white,
                enableActiveFill: true,
                onChanged: (value) {
                  setState(() {
                    _otp = value;
                  });
                },
              ),

              SizedBox(height: 32.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(context: context, builder: (context) => Center(child: CircularProgressIndicator(),));
                    if (widget.otp == _otp) {
                      print('Mã xác thực chính xác');
                      Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => Information(
                          tempData: {
                            ...widget.tempData
                          },
                        ),
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Mã sai vui lòng kiểm tra lại',
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );

                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E2157),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text("Send",
                      style: TextStyle(fontSize: 16.sp, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}