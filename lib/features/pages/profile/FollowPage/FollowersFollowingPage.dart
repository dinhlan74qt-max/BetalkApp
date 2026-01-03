import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/userModel.dart';
import 'FollowerListView.dart';
import 'FollowingListView.dart';

class FollowersFollowingPage extends StatefulWidget {
  final String userId;
  final int initialIndex;
  final String? userName;
  final List<UserModel> listFollowing;
  final List<UserModel> listFollower;

  const FollowersFollowingPage({
    super.key,
    required this.userId,
    this.initialIndex = 0,
    required this.userName,
    required this.listFollowing,
    required this.listFollower,
  });

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int followingCount = 0;
  @override
  void initState() {
    super.initState();
    followingCount = widget.listFollowing.length;
    _tabController = TabController(
      length: 2, // Hai tab
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final title = widget.userName ?? 'Người dùng';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 2.0,
          labelStyle: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: '${widget.listFollower.length} Người theo dõi'),
            Tab(text: '$followingCount Đang theo dõi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FollowerListView(
            userList: widget.listFollower,
            currentUserId: widget.userId,
          ),

          FollowingListView(
            userList: widget.listFollowing,
            currentUserId: widget.userId,
            onUnfollow: (remove){
              if(remove){
                setState(() {
                  followingCount--;
                });
              }else{
                setState(() {
                  followingCount++;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

