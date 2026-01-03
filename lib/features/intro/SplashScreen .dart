import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Image.asset(
                'assets/logos/logoUnicon.png',
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 32.h),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.grey), // chữ xám nhạt
                  children: [
                    TextSpan(text: 'Bản quyền thuộc '),
                    TextSpan(
                      text: 'Betalk',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // chữ Betalk đậm và đen
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
