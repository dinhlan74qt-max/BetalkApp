import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/userModel.dart';

class FollowerListView extends StatelessWidget {
  final List<UserModel> userList;
  final String currentUserId;

  const FollowerListView({
    super.key,
    required this.userList,
    required this.currentUserId,
  });

  Widget _buildTile(UserModel user) {
    const bool isCurrentlyFollowingBack = false;

    return ListTile(
      leading: CircleAvatar(
        radius: 25.r,
        backgroundImage: CachedNetworkImageProvider(
          user.avatarUrl.isNotEmpty ? user.avatarUrl : 'https://placehold.co/100x100/EFEFEF/AAAAAA?text=U',
        ) as ImageProvider,
        backgroundColor: Colors.grey[200],
      ),
      title: Text(
        user.fullName,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
      ),
      subtitle: Text(
        '@${user.userName}',
        style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          print('Follow back/Remove clicked for ${user.userName}');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentlyFollowingBack ? Colors.grey[300] : Colors.blueAccent,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        child: Text(
          isCurrentlyFollowingBack ? 'Đang theo dõi' : 'Theo dõi lại',
          style: TextStyle(
            color: isCurrentlyFollowingBack ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
      onTap: () {
        print('Tapped on ${user.userName}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userList.isEmpty) {
      return Center(
        child: Text(
          'Chưa có người theo dõi nào.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: userList.length,
      itemBuilder: (context, index) {
        final user = userList[index];
        return _buildTile(user);
      },
    );
  }
}