import 'package:flutter/material.dart';
import 'package:socialnetwork/data/server/emailApi/EmailApi.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'otpEmail.dart';

class EmailConfirmation extends StatefulWidget {
  final Map<String, dynamic> tempData;

  const EmailConfirmation({super.key, required this.tempData});

  @override
  State<EmailConfirmation> createState() => _EmailConfirmationState();
}

class _EmailConfirmationState extends State<EmailConfirmation> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực Email'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Xác thực Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Để xác thực email, chúng tôi sẽ gửi mã về email "${widget.tempData['email']}" của bạn để xác thực. Vui lòng nhấn nút gửi để chúng tôi gửi mã đến email của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      final resultSendOtp = await EmailApi.sendOtp(widget.tempData['email'],);
                      if(resultSendOtp['success']){
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mã OTP đã được gửi thành công!'),
                          ),
                        );

                        Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) =>
                            OtpEmail(
                              otp: resultSendOtp['otp'],
                              tempData: {...widget.tempData},
                            ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                          transitionDuration: const Duration(
                            milliseconds: 1000,
                          ),
                        ),
                        );
                      }else {
                        print('Loi gui ma email: ${resultSendOtp['error']}');
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Hệ thống bận vui lòng thử lại sau',
                                  style: TextStyle(
                                    fontSize: 12.sp
                                  ),
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
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Gửi mã',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
