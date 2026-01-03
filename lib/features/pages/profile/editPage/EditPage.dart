import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProfilePage extends StatelessWidget {
  final String avatarUrl = "";
  final String fullName = "Nguyễn Đình Lân";
  final String username = "ndlan.05";

  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chỉnh sửa trang cá nhân",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 15.h),

            /// --- Avatar + Chỉnh sửa avatar ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45.r,
                  backgroundImage: avatarUrl.isEmpty
                      ? const AssetImage("assets/images/avtMacDinh.jpg")
                      : NetworkImage(avatarUrl) as ImageProvider,
                ),
                SizedBox(width: 20.w),
                CircleAvatar(
                  radius: 45.r,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.face_retouching_natural,
                      size: 40, color: Colors.black),
                ),
              ],
            ),

            SizedBox(height: 10.h),
            const Text(
              "Chỉnh sửa ảnh hoặc avatar",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 20.h),

            /// --- Form Edit Items ---
            _buildEditItem("Tên", fullName,(){}),
            _buildEditItem("Tên người dùng", username,(){}),
            _buildEditItem("Tiểu sử", "Tiểu sử",(){}),



            const Divider(height: 0),

            _buildArrow("Giới tính", "Nam"),
            _buildArrow("Cài đặt thông tin cá nhân"),

            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  /// ----------------------------------------------------------
  /// Item dạng: Tên      Nguyễn Đình Lân
  /// ----------------------------------------------------------
  Widget _buildEditItem(String title, String value,VoidCallback onTap ,{bool showArrow = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black87)),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                if (showArrow)
                  const Icon(Icons.chevron_right, color: Colors.grey)
              ],
            )
          ],
        ),
      ),
    );
  }

  /// ----------------------------------------------------------
  /// Item chỉ có mũi tên: Giới tính  >
  /// ----------------------------------------------------------
  Widget _buildArrow(String title, [String? value]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, color: Colors.black)),
          Row(
            children: [
              if (value != null)
                Text(
                  value,
                  style:
                  const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              const Icon(Icons.chevron_right, color: Colors.grey)
            ],
          )
        ],
      ),
    );
  }
}
