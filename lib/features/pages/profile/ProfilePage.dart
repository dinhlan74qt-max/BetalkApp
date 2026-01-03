import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:socialnetwork/core/widget/TextBasic.dart';
import 'package:socialnetwork/data/models/PostModel/ArticleModel.dart';
import 'package:socialnetwork/data/models/PostModel/RepostModel.dart';
import 'package:socialnetwork/data/models/ReelModel/ReelModel.dart';
import 'package:socialnetwork/data/repositories/prefs/UserPrefsService.dart';
import 'package:socialnetwork/data/server/user/UserApi.dart';
import 'package:socialnetwork/features/pages/profile/FollowPage/FollowersFollowingPage.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/ImageTab/ImageTab.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/ReelTab/ReelsTab.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/RepostTab/RepostTab.dart';
import 'package:socialnetwork/features/pages/profile/settingPage/SettingPage.dart';
import '../../../data/models/userModel.dart';
import 'editPage/EditPage.dart';

class ProfilePage extends StatefulWidget {
  final UserModel userModel;

  const ProfilePage({
    super.key,
    required this.userModel
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late UserModel user;
  List<UserModel> listFollowing = [];
  List<UserModel> listFollower = [];
  List<ArticleModel> listArticle = [];
  List<ReelModel> listReel = [];
  List<RepostModel> listRepost = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ Biến để track refresh state
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    user = widget.userModel;

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

  Future<void> _loadData() async {
    await Future.wait([
      getFollowing(),
      getFollowers(),
      getPost(),
      getReel(),
      getRepost(),
    ]);
  }

  Future<void> getFollowing() async {
    final List<UserModel> listFromApi = await UserApi.getFollowing(widget.userModel.id);
    if (mounted) {
      setState(() {
        listFollowing = listFromApi;
      });
    }
  }

  Future<void> getFollowers() async {
    final List<UserModel> listFromApi = await UserApi.getFollowers(widget.userModel.id);
    if (mounted) {
      setState(() {
        listFollower = listFromApi;
      });
    }
  }

  Future<void> getPost() async {
    final List<ArticleModel> listFromApi = await UserApi.getPostById(widget.userModel.id);
    if (mounted) {
      setState(() {
        listArticle = listFromApi;
      });
    }
  }

  Future<void> getRepost() async {
    final List<RepostModel> listFromApi = await UserApi.getRepostById(widget.userModel.id);
    if (mounted) {
      setState(() {
        listRepost = listFromApi;
      });
    }
  }

  Future<void> getReel() async {
    final List<ReelModel> listFromApi = await UserApi.getReelById(widget.userModel.id);
    if (mounted) {
      setState(() {
        listReel = listFromApi;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ).createShader(bounds),
            child: Text(
              user.userName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF667EEA).withOpacity(0.1),
                    Color(0xFF764BA2).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: IconButton(
                onPressed: () => _openPopup(context),
                icon: Icon(
                  Icons.add_box_outlined,
                  size: 24.r,
                  color: Color(0xFF667EEA),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const SettingPage(),
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
                },
                icon: Icon(Icons.menu_rounded, size: 24.r, color: Colors.black87),
              ),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            // ✅ GIẢI PHÁP: BỌC TOÀN BỘ VÀO CustomScrollView với RefreshIndicator
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: Color(0xFF667EEA),
              strokeWidth: 2.5,
              child: CustomScrollView(
                // ✅ QUAN TRỌNG: Cho phép scroll ngay cả khi content ngắn
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header Profile
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              children: [
                                // Avatar and Stats Row
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
                                            color: const Color(0xFF667EEA).withOpacity(0.3),
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
                                          backgroundImage: user.avatarUrl == '0'
                                              ? const AssetImage("assets/images/avtMacDinh.jpg")
                                              : CachedNetworkImageProvider(user.avatarUrl) as ImageProvider,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20.w),
                                    // Stats
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatColumn(
                                            user.postsCount.toString(),
                                            "Bài viết",
                                                () {},
                                          ),
                                          _buildStatColumn(
                                            user.followersCount.toString(),
                                            "Theo dõi",
                                                () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                                      FollowersFollowingPage(
                                                        userId: widget.userModel.id,
                                                        userName: widget.userModel.userName,
                                                        initialIndex: 0,
                                                        listFollowing: listFollowing,
                                                        listFollower: listFollower,
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
                                            },
                                          ),
                                          _buildStatColumn(
                                            user.followingCount.toString(),
                                            "Đang theo",
                                                () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                                      FollowersFollowingPage(
                                                        userId: widget.userModel.id,
                                                        userName: widget.userModel.userName,
                                                        initialIndex: 1,
                                                        listFollowing: listFollowing,
                                                        listFollower: listFollower,
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
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Name and Bio
                                SizedBox(height: 12.h),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName,
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (user.bio != '0') ...[
                                        SizedBox(height: 6.h),
                                        Text(
                                          user.bio,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13.sp,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Action Buttons
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGradientButton(
                                        "Chỉnh sửa",
                                        Icons.edit_outlined,
                                            () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) =>
                                              const EditProfilePage(),
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
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: _buildSecondaryButton(
                                        "Chia sẻ",
                                        Icons.share_outlined,
                                            () async {
                                          await UserPrefsService.printUser();
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    _buildIconButton(
                                      CupertinoIcons.person_add,
                                          () {},
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
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
                          Tab(icon: Icon(Icons.grid_on, size: 24.r)),
                          Tab(
                            icon: FaIcon(
                              FontAwesomeIcons.repeat,
                              size: 20.r,
                            ),
                          ),
                          Tab(
                            icon: FaIcon(
                              FontAwesomeIcons.film,
                              size: 20.r,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ TabBarView content - đặt trong SliverFillRemaining
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: TabBarView(
                      children: [
                        ImageTab(userModel: widget.userModel, listArticleModel: listArticle),
                        RepostTab(userModel: widget.userModel, listRepostModel: listRepost),
                        ReelsTab(userModel: widget.userModel, listReelModel: listReel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, VoidCallback onTab) {
    return GestureDetector(
      onTap: onTab,
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ).createShader(bounds),
            child: Text(
              count,
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
      ),
    );
  }

  Widget _buildGradientButton(String text, IconData icon, VoidCallback onTap) {
    return Container(
      height: 38.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16.sp, color: Colors.white),
                SizedBox(width: 6.w),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon, VoidCallback onTap) {
    return Container(
      height: 38.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16.sp, color: Colors.black87),
                SizedBox(width: 6.w),
                Text(
                  text,
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
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 38.w,
      height: 38.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Icon(
            icon,
            size: 18.sp,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _customNavigatorButton(Widget icon, String hint, VoidCallback onTap) {
    return ListTile(
      leading: icon,
      title: customText(
        text: hint,
        color: Colors.black87,
        fonSize: 14.sp,
        fonWeight: FontWeight.w500,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  void _openPopup(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          padding: EdgeInsets.only(top: 8.h, bottom: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ).createShader(bounds),
                child: Text(
                  'Tạo',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Divider(height: 1, thickness: 1, color: Colors.grey[200]),
              _customNavigatorButton(
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF667EEA).withOpacity(0.1),
                        Color(0xFF764BA2).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.film,
                    size: 18.sp,
                    color: Color(0xFF667EEA),
                  ),
                ),
                'Thước phim',
                    () {},
              ),
              _customNavigatorButton(
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE91E63).withOpacity(0.1),
                        Color(0xFFF06292).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.heart,
                    size: 18.sp,
                    color: Color(0xFFE91E63),
                  ),
                ),
                'Bài viết',
                    () {},
              ),
              _customNavigatorButton(
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4CAF50).withOpacity(0.1),
                        Color(0xFF66BB6A).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.circlePlus,
                    size: 18.sp,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                'Tin',
                    () {},
              ),
              _customNavigatorButton(
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF9800).withOpacity(0.1),
                        Color(0xFFFFB74D).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.robot,
                    size: 18.sp,
                    color: Color(0xFFFF9800),
                  ),
                ),
                'AI',
                    () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return; // Tránh refresh nhiều lần cùng lúc

    setState(() {
      _isRefreshing = true;
    });

    try {
      print('🔄 Bắt đầu refresh...');

      final results = await Future.wait([
        UserApi.getUserById(widget.userModel.id),
        UserApi.getFollowing(widget.userModel.id),
        UserApi.getFollowers(widget.userModel.id),
        UserApi.getPostById(widget.userModel.id),
        UserApi.getReelById(widget.userModel.id),
        UserApi.getRepostById(widget.userModel.id),
      ]);

      final newUser = results[0] as UserModel;
      final newFollowing = results[1] as List<UserModel>;
      final newFollower = results[2] as List<UserModel>;
      final newArticle = results[3] as List<ArticleModel>;
      final newReel = results[4] as List<ReelModel>;
      final newRepost = results[5] as List<RepostModel>;

      await UserPrefsService.saveUser(newUser);

      if (mounted) {
        setState(() {
          user = newUser;
          listFollowing = newFollowing;
          listFollower = newFollower;
          listArticle = newArticle;
          listReel = newReel;
          listRepost = newRepost;
        });
      }

      print('✅ Refresh thành công!');
    } catch (e) {
      print('❌ Lỗi khi refresh: $e');
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
}

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