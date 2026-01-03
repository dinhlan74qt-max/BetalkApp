import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:socialnetwork/core/widget/TextBasic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/data/server/user/UserApi.dart';
import 'package:socialnetwork/features/pages/message/ChatPage.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/ImageTab/ImageTab.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/ReelTab/ReelsTab.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/RepostTab/RepostTab.dart';
import '../../../data/models/PostModel/ArticleModel.dart';
import '../../../data/models/PostModel/RepostModel.dart';
import '../../../data/models/ReelModel/ReelModel.dart';
import '../../../data/models/userModel.dart';

class UserPage extends StatefulWidget {
  final String myId;
  final UserModel userModel;

  const UserPage({super.key, required this.myId, required this.userModel});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage>
    with SingleTickerProviderStateMixin {
  bool isFollowing = true;
  bool isLoading = true;
  List<ArticleModel> listArticle = [];
  List<ReelModel> listReel = [];
  List<RepostModel> listRepost = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int follower = 0;

  // ✅ Thêm biến để track refresh state
  bool _isRefreshing = false;

  // ✅ Thêm UserModel để có thể cập nhật
  late UserModel user;

  @override
  void initState() {
    super.initState();
    user = widget.userModel;
    follower = widget.userModel.followersCount;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _loadData();
    });
  }

  Future<void> getPost() async {
    final List<ArticleModel> listFromApi = await UserApi.getPostById(
      widget.userModel.id,
    );
    if (mounted) {
      setState(() {
        listArticle = listFromApi;
      });
    }
  }

  Future<void> getReel() async {
    final List<ReelModel> listFromApi = await UserApi.getReelById(
      widget.userModel.id,
    );
    if (mounted) {
      setState(() {
        listReel = listFromApi;
      });
    }
  }

  Future<void> checkFollow() async {
    final result = await UserApi.checkFollow(widget.myId, widget.userModel.id);
    if (result['success']) {
      final check = result['status'];
      if (mounted) {
        setState(() {
          isFollowing = check;
          isLoading = false;
        });
      }
    } else {
      print(result['error']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Có lỗi trong lúc hiển thị dữ liệu. Vui lòng thử lại sau !',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> getRepost() async {
    final List<RepostModel> listFromApi = await UserApi.getRepostById(
      widget.userModel.id,
    );
    if (mounted) {
      setState(() {
        listRepost = listFromApi;
      });
    }
  }

  void _startChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
          myId: widget.myId,
          targetUserId: widget.userModel.id,
          targetUser: widget.userModel,
          isOnline: widget.userModel.isOnline,
          time: widget.userModel.lastActive,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );

          return SlideTransition(
            position: tween.animate(curvedAnimation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _loadData() async {
    await Future.wait([checkFollow(), getPost(), getReel(), getRepost()]);
  }

  // ✅ Thêm hàm _onRefresh
  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      print('🔄 Bắt đầu refresh UserPage...');

      final results = await Future.wait([
        UserApi.getUserById(widget.userModel.id),
        UserApi.getPostById(widget.userModel.id),
        UserApi.getReelById(widget.userModel.id),
        UserApi.getRepostById(widget.userModel.id),
        UserApi.checkFollow(widget.myId, widget.userModel.id),
      ]);

      final newUser = results[0] as UserModel;
      final newArticle = results[1] as List<ArticleModel>;
      final newReel = results[2] as List<ReelModel>;
      final newRepost = results[3] as List<RepostModel>;
      final followResult = results[4] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          user = newUser;
          follower = newUser.followersCount;
          listArticle = newArticle;
          listReel = newReel;
          listRepost = newRepost;

          if (followResult['success']) {
            isFollowing = followResult['status'];
          }
        });
      }

      print('✅ Refresh UserPage thành công!');
    } catch (e) {
      print('❌ Lỗi khi refresh UserPage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể làm mới dữ liệu'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.chevron_left, size: 28.sp, color: Colors.black87),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ).createShader(bounds),
            child: Text(
              user.userName,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.more_vert, color: Colors.black87, size: 22.sp),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            // ✅ BỌC RefreshIndicator VÀ NestedScrollView
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: Color(0xFF667EEA),
              strokeWidth: 2.5,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Avatar with gradient border
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF667EEA,
                                        ).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(3.w),
                                  child: CircleAvatar(
                                    radius: 40.r,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 37.r,
                                      backgroundImage:
                                      user.avatarUrl == '0'
                                          ? const AssetImage(
                                        "assets/images/avtMacDinh.jpg",
                                      )
                                          : CachedNetworkImageProvider(
                                        user.avatarUrl,
                                      )
                                      as ImageProvider,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                // Stats
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatColumn(
                                        user.postsCount.toString(),
                                        "Bài viết",
                                      ),
                                      _buildStatColumn(
                                        follower.toString(),
                                        "Theo dõi",
                                      ),
                                      _buildStatColumn(
                                        user.followingCount.toString(),
                                        "Đang theo",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            // Full name
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                user.fullName,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            // Bio
                            if (user.bio != '0') ...[
                              SizedBox(height: 6.h),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  user.bio,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 16.h),
                            // Action buttons
                            Row(
                              children: [
                                // Follow/Following button
                                Expanded(
                                  flex: 2,
                                  child: isLoading
                                      ? Container(
                                    height: 38.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                            Color(0xFF667EEA),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                      : Container(
                                    height: 38.h,
                                    decoration: BoxDecoration(
                                      gradient: isFollowing
                                          ? null
                                          : const LinearGradient(
                                        colors: [
                                          Color(0xFF667EEA),
                                          Color(0xFF764BA2),
                                        ],
                                      ),
                                      color: isFollowing
                                          ? Colors.grey[200]
                                          : null,
                                      borderRadius: BorderRadius.circular(10.r),
                                      boxShadow: !isFollowing
                                          ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF667EEA,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                          : [],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: isFollowing
                                            ? () async {
                                          _handleUnFollow();
                                        }
                                            : () async {
                                          await _handleFollow();
                                        },
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                isFollowing
                                                    ? Icons.check
                                                    : Icons.person_add,
                                                size: 16.sp,
                                                color: isFollowing
                                                    ? Colors.black87
                                                    : Colors.white,
                                              ),
                                              SizedBox(width: 6.w),
                                              Text(
                                                isFollowing
                                                    ? 'Đang theo dõi'
                                                    : 'Theo dõi',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: isFollowing
                                                      ? Colors.black87
                                                      : Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                // Message button
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 38.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _startChat,
                                        borderRadius: BorderRadius.circular(10.r),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                CupertinoIcons.chat_bubble_text_fill,
                                                size: 16.sp,
                                                color: Colors.black87,
                                              ),
                                              SizedBox(width: 6.w),
                                              Text(
                                                'Nhắn tin',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                // More button
                                Container(
                                  width: 38.w,
                                  height: 38.h,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {},
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Icon(
                                        CupertinoIcons.person_add_solid,
                                        size: 18.sp,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 2.h),
                    ),
                    // TabBar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyTabBarDelegate(
                        TabBar(
                          indicatorColor: const Color(0xFF667EEA),
                          indicatorWeight: 3,
                          labelColor: const Color(0xFF667EEA),
                          unselectedLabelColor: Colors.grey,
                          tabs: [
                            Tab(icon: Icon(Icons.grid_on, size: 24.sp)),
                            Tab(icon: FaIcon(FontAwesomeIcons.repeat, size: 20.sp)),
                            Tab(icon: FaIcon(FontAwesomeIcons.film, size: 20.sp)),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                // TabBarView
                body: TabBarView(
                  children: [
                    ImageTab(
                      userModel: user,
                      listArticleModel: listArticle,
                    ),
                    RepostTab(
                      userModel: user,
                      listRepostModel: listRepost,
                    ),
                    ReelsTab(
                      userModel: user,
                      listReelModel: listReel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ).createShader(bounds),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _handleFollow() async {
    setState(() {
      follower++;
      isFollowing = true;
    });
    final result = await UserApi.followUser(widget.myId, widget.userModel.id);
    if (result['success']) {
      if (mounted) {
        setState(() {
          isFollowing = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          follower--;
          isFollowing = false;
        });
        print(result['error']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Có lỗi trong lúc theo người người dùng. Vui lòng thử lại sau !',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUnFollow() async {
    setState(() {
      follower--;
      isFollowing = false;
    });
    final result = await UserApi.unFollowUser(widget.myId, widget.userModel.id);
    if (result['success']) {
      if (mounted) {
        setState(() {
          isFollowing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          follower++;
          isFollowing = true;
        });
        print(result['error']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Có lỗi trong lúc bỏ theo người người dùng. Vui lòng thử lại sau !',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ✅ Thêm StickyTabBarDelegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}