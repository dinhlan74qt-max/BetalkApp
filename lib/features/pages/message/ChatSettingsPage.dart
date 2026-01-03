import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatSettingsPage extends StatefulWidget {
  final String userName;
  final String avatarUrl;

  const ChatSettingsPage({
    super.key,
    this.userName = 'Duyen', // Giá trị mặc định từ ảnh mẫu
    this.avatarUrl = 'https://placehold.co/100x100/CCCCCC/white?text=D',
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10.h),
            // 1. Header (Avatar + Tên)
            _buildHeader(),

            SizedBox(height: 24.h),

            // 2. Action Buttons Row
            _buildActionButtonsRow(),

            SizedBox(height: 24.h),

            // 3. Settings List
            _buildSettingsList(),
          ],
        ),
      ),
    );
  }

  // Widget: Header
  Widget _buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50.r,
          backgroundImage: NetworkImage(widget.avatarUrl),
          backgroundColor: Colors.grey[200],
        ),
        SizedBox(height: 12.h),
        Text(
          widget.userName,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // Widget: Action Buttons Row
  Widget _buildActionButtonsRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.person_outline,
            label: 'Trang',
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.search,
            label: 'Tìm kiếm',
            onTap: () {},
          ),
          _buildActionButton(
            icon: Icons.notifications_none,
            label: 'Tắt',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // Helper: Single Action Button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28.sp, color: Colors.black),
          SizedBox(height: 8.h),
          SizedBox(
            width: 70.w, // Giới hạn chiều rộng để text xuống dòng nếu cần
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Settings List
  Widget _buildSettingsList() {
    return Column(
      children: [
        // Chủ đề
        _buildListTile(
          leading: Container(
            width: 32.w,
            height: 32.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: 'Chủ đề',
          subtitle: 'Mặc định',
          onTap: () {},
        ),

        // Biệt danh
        _buildListTile(
          leadingIcon: Icons.font_download_outlined, // Hoặc icon tương tự
          title: 'Biệt danh',
          onTap: () {},
        ),
        // Tạo nhóm chat
        _buildListTile(
          leadingIcon: Icons.group_add_outlined,
          title: 'Tạo nhóm chat',
          onTap: () {},
        ),


        // Đã xảy ra lỗi
        _buildListTile(
          leadingIcon: Icons.report_problem_outlined, // Hoặc chat bubble warning
          title: 'Đã xảy ra lỗi',
          onTap: () {},
        ),
      ],
    );
  }

  // Helper: Build List Tile
  Widget _buildListTile({
    Widget? leading,
    IconData? leadingIcon,
    Widget? customLeading,
    required String title,
    String? subtitle,
    Color titleColor = Colors.black,
    Color iconColor = Colors.black,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: leading ??
          customLeading ??
          Icon(leadingIcon, size: 26.sp, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          fontSize: 13.sp,
          color: Colors.grey[600],
        ),
      )
          : null,
      trailing: showArrow
          ? Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey)
          : null,
    );
  }
}