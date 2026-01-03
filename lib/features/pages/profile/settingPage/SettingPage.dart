import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/main.dart' hide MyApp;
import 'package:socialnetwork/core/widget/TextBasic.dart';

import '../../../../data/server/WebSocketService.dart';
import '../../../../main.dart';
import '../../../auth/loginPage.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final _socketService = WebSocketService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf9f9f9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.chevron_left, size: 30.sp),
        ),
        title: customText(
          text: 'Cài đặt và hoạt động của bạn',
          color: Colors.black,
          fonSize: 16.sp,
          fonWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildAccount('Tài khoản của bạn', 'assets/logos/logoUnicon.png', 'Betalk',),
                SizedBox(height: 4.h,),
                _buildField1('Cách bạn dùng Betalk'),
                SizedBox(height: 4.h,),
                _buildField2('Ai có thể xem nội dung của bạn'),
                SizedBox(height: 4.h,),
                _buildField3('Đăng nhập')
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccount(String hint, String logo, String name) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 20.w),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              customText(text: hint, color: Colors.grey.shade400, fonSize: 14.sp, fonWeight: FontWeight.normal,),
              Row(
                children: [
                  Image.asset(logo, width: 20.w, height: 20.h),
                  customText(text: name, color: Colors.grey.shade600, fonSize: 14.sp, fonWeight: FontWeight.normal,),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ListTile(
            leading: Icon(
              Icons.account_circle_outlined,
              size: 30.r,
              color: Colors.black,
            ),
            title: const Text(
              'Trung tâm tài khoản',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
            subtitle: const Text(
              'Mật khẩu, bảo mật, thông tin cá nhân, tùy chọn quảng cáo',
              style: TextStyle(
                color: Colors.grey, // Màu chữ xám nhạt như trong ảnh
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
            },
            contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
          ),
        ],
      ),
    );
  }

  Widget _buildField1(String hint){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(text: hint, color: Colors.grey.shade500, fonSize: 14.sp, fonWeight: FontWeight.normal),
          _customTiTle(Icons.bookmark_border, 'Đã lưu', (){}),
          _customTiTle(CupertinoIcons.timer, 'Kho lưu trữ', (){}),
          _customTiTle(Icons.show_chart, 'Hoạt động của bạn', (){}),
          _customTiTle(Icons.notifications_active_outlined, 'Thông báo', (){}),
        ],
      ),
    );
  }
  Widget _buildField2(String hint){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(text: hint, color: Colors.grey.shade500, fonSize: 14.sp, fonWeight: FontWeight.normal),
          _customTiTle(CupertinoIcons.lock, 'Quyền riêng tư của tài khoản', (){}),
          _customTiTle(CupertinoIcons.star_circle, 'Bạn thân', (){}),
          _customTiTle(Icons.block, 'Đã chặn', (){}),
        ],
      ),
    );
  }
  Widget _buildField3(String hint){
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          customText(text: hint, color: Colors.grey.shade500, fonSize: 14.sp, fonWeight: FontWeight.normal),
          SizedBox(height: 15.h,),
          customText(text: 'Thêm tài khoản', color: Color(0xFF666dd9), fonSize: 14.sp, fonWeight: FontWeight.normal),
          SizedBox(height: 15.h,),
          GestureDetector(
              onTap: (){
                _handleLogout();
              },
              child: customText(text: 'Đăng xuất', color: Colors.red, fonSize: 14.sp, fonWeight: FontWeight.normal)
          ),

        ],
      ),
    );
  }
  Widget _customTiTle(IconData icon, String title,VoidCallback onTap){
    return ListTile(
      leading: Icon(
        icon,
        size: 30.r,
        color: Colors.black,
      ),
      title: customText(text: title, color: Colors.black, fonSize: 14.sp, fonWeight: FontWeight.normal),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
    );
    
  }
  Future<void> _handleLogout() async {
    // Hiển thị dialog xác nhận
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      // Ngắt WebSocket
      await _socketService.disconnect();

      // Xóa dữ liệu user
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('story_cloud_list');

      // Cập nhật userId trong MyApp
      if (mounted) {
        MyApp.updateUserId(context, null);

        // Navigate to LoginPage
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      print('❌ Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi đăng xuất. Vui lòng thử lại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
