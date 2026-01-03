import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/data/server/user/UserApi.dart';
import 'package:socialnetwork/features/pages/search/UserPage.dart';
import '../../../../data/models/userModel.dart';

class FollowingListView extends StatefulWidget {
  final List<UserModel> userList;
  final String currentUserId;
  final Function(bool) onUnfollow;

   const FollowingListView({
    super.key,
    required this.userList,
    required this.currentUserId,
    required this.onUnfollow,
  });

  @override
  State<FollowingListView> createState() => _FollowingListViewState();
}

class _FollowingListViewState extends State<FollowingListView> {
  // Copy danh sách để có thể setState
  late List<UserModel> displayedList;

  @override
  void initState() {
    super.initState();
    displayedList = List.from(widget.userList);
  }

  Widget _buildTile(BuildContext context, UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25.r,
        backgroundImage: CachedNetworkImageProvider(
          user.avatarUrl.isNotEmpty
              ? user.avatarUrl
              : 'https://placehold.co/100x100/EFEFEF/AAAAAA?text=U',
        ),
        backgroundColor: Colors.grey[200],
      ),
      title: Text(
        user.fullName,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
      ),
      subtitle: Text(
        '@${user.userName}',
        style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () => _showOptionSheet(context, user),
      ),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => UserPage(myId: widget.currentUserId, userModel: user),
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
              milliseconds: 500,
            ), // Rút ngắn thời gian chuyển cảnh
          ),
        );
      },
    );
  }

  void _showOptionSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text(
                  'Hủy theo dõi',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  setState(() {
                    displayedList.removeWhere((u) => u.id == user.id);
                  });
                  widget.onUnfollow(true);
                  Navigator.pop(context);
                  _unfollowUser(user);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Đóng'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _unfollowUser(UserModel user) async {
    final result = await UserApi.unFollowUser(widget.currentUserId, user.id);
    if(!result['success']){
      setState(() {
        displayedList.add(user);
        widget.onUnfollow(false);
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    if (displayedList.isEmpty) {
      return Center(
        child: Text(
          'Bạn chưa theo dõi ai.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16.sp),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: displayedList.length,
      itemBuilder: (context, index) {
        final user = displayedList[index];
        return _buildTile(context, user);
      },
    );
  }
}
