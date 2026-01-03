import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialnetwork/data/models/PostModel/DetailsModel.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/repositories/prefs/StoryPrefsService.dart';
import 'package:socialnetwork/data/server/WebSocketService.dart';
import 'package:socialnetwork/data/server/postApi/PostApi.dart';
import 'package:socialnetwork/data/server/story/StoryApi.dart';
import 'package:socialnetwork/features/pages/home/PostCard.dart';
import 'package:socialnetwork/features/pages/home/PostCardSkeleton.dart';
import 'package:socialnetwork/features/pages/home/story/AddStoryPage.dart';
import 'package:socialnetwork/features/pages/home/story/MyStoryView.dart';
import 'package:socialnetwork/features/pages/home/story/StoryViewerPage.dart';
import 'package:socialnetwork/features/pages/message/ChatListPage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/StoryModel/DetailsStory.dart';
import '../../../data/models/StoryModel/StoryCloud.dart';
import '../../../data/models/StoryModel/UserStoryGroup.dart';

class HomePage extends StatefulWidget {
  final UserModel userModel;
  const HomePage({Key? key, required this.userModel}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _socketService = WebSocketService();
  bool _isOnline = false;
  String? _userName;
  List<DetailsModel> listPost = [];
  bool _isLoading = true;

  bool _hasMyStory = false;
  bool _isStoryLoaded = false;
  Map<String, UserStoryGroup> grouped = {};
  UserStoryGroup? _myStory;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadUserInfo();
    _getPost();
    _listenToConnection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _loadStoryFromLocal().then((_) {
        _loadStoryFromApi();
      });
    });
  }

  Future<void> _loadStoryFromLocal() async {
    final List<StoryCloud> listStoryLocal = await StoryPrefsService.loadStoryCloudList();
    grouped.clear();
    for (var storyCloud in listStoryLocal) {
      final user = storyCloud.detailsStory.userModel;
      final uid = user!.id;
      if (!grouped.containsKey(uid)) {
        grouped[uid] = UserStoryGroup(user: user, stories: []);
      }
      grouped[uid]!.stories.add(storyCloud);
    }
    final currentUserId = widget.userModel.id;

    final bool hasMine = grouped.containsKey(currentUserId);
    UserStoryGroup? mine;
    if (hasMine) {
      mine = grouped[currentUserId];
    }
    setState(() {
      _hasMyStory = hasMine;
      _myStory = mine;
      _isStoryLoaded = true;
    });
  }

  Future<void> _loadStoryFromApi() async {
    final List<DetailsStory> listFromApi = await StoryApi.getStory(widget.userModel.id);
    await StoryPrefsService.syncStoriesFromApi(listFromApi);
    final updatedList = await StoryPrefsService.loadStoryCloudList();

    grouped.clear();
    for (var storyCloud in updatedList) {
      final user = storyCloud.detailsStory.userModel;
      final uid = user!.id;
      if (!grouped.containsKey(uid)) {
        grouped[uid] = UserStoryGroup(user: user, stories: []);
      }
      grouped[uid]!.stories.add(storyCloud);
    }
    final currentUserId = widget.userModel.id;

    final bool hasMine = grouped.containsKey(currentUserId);
    UserStoryGroup? mine;
    if (hasMine) {
      mine = grouped[currentUserId];
    }
    setState(() {
      _hasMyStory = hasMine;
      _myStory = mine;
      _isStoryLoaded = true;
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });

    if (_socketService.isConnected) {
      setState(() {
        _isOnline = true;
      });
    }
  }

  Future<void> _getPost() async {
    try {
      final list = await PostApi.getPost(widget.userModel.id);
      print('So luong bai lay duoc: ${list.length}');

      if (mounted) {
        setState(() {
          listPost = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('loi: ${e.toString()}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _listenToConnection() {
    _socketService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
  }

  Future<void> _refreshAll() async {
    await _getPost();
    await _loadStoryFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildStorySection(),
            Expanded(child: _buildBody())
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ).createShader(bounds),
            child: Text(
              'Betalk',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? Colors.green : Colors.grey,
                    boxShadow: _isOnline
                        ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                        : [],
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 12.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              CupertinoIcons.chat_bubble_text_fill,
              color: const Color(0xFF667EEA),
              size: 22.sp,
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ChatListPage(myId: widget.userModel.id),
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
      ],
    );
  }

  Widget _buildStorySection() {
    return Container(
      margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 110.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                if (!_isStoryLoaded) _buildEditMyStory(),
                if (_isStoryLoaded && !_hasMyStory) _buildEditMyStory(),
                if (_isStoryLoaded && _hasMyStory) _buildMyStory(),
                SizedBox(width: 12.w),
                ...grouped.values
                    .where((g) => g.user.id != widget.userModel.id)
                    .map((g) => _buildStoryUser(g)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStory() {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => MyStoryView(userStory: _myStory!, initialIndex: 0),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: CircleAvatar(
                  backgroundImage: widget.userModel.avatarUrl == '0'
                      ? const AssetImage('assets/images/avtMacDinh.jpg')
                      : CachedNetworkImageProvider(widget.userModel.avatarUrl) as ImageProvider,
                  backgroundColor: Colors.grey[300],
                ),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'Tin của bạn',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditMyStory() {
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      child: GestureDetector(
        onTap: _isStoryLoaded
            ? () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AddStoryPage(userModel: widget.userModel),
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
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
            : null,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 57.w,
                  height: 57.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: widget.userModel.avatarUrl == '0'
                        ? const AssetImage('assets/images/avtMacDinh.jpg')
                        : CachedNetworkImageProvider(widget.userModel.avatarUrl) as ImageProvider,
                    radius: 36.r,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Tạo tin',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryUser(UserStoryGroup userStoryGroup){
    bool isRead = userStoryGroup.stories.every((story) => story.isRead);
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      child: GestureDetector(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => StoryViewerPage(
                userStory: userStoryGroup,
                initialIndex: 0,
              ),
            ),
          );
          for (var story in userStoryGroup.stories) {
            await StoryPrefsService.editViewedStatus(story.detailsStory.storyModel.idStory);
            await StoryApi.viewedStory(story.detailsStory.storyModel.idStory, widget.userModel.id);
          }
          setState(() {
            _loadStoryFromLocal();
          });
        },
        child: Column(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                gradient: !isRead
                    ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                ),
                shape: BoxShape.circle,
                boxShadow: !isRead
                    ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: CircleAvatar(
                  backgroundImage: userStoryGroup.user.avatarUrl == '0'
                      ? const AssetImage('assets/images/avtMacDinh.jpg')
                      : CachedNetworkImageProvider(userStoryGroup.user.avatarUrl) as ImageProvider,
                  backgroundColor: Colors.grey[300],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: 72.w,
              child: Text(
                userStoryGroup.user.userName,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return const PostCardSkeleton();
        },
      );
    }

    if (listPost.isEmpty) {
      return const EmptyPostsWidget();
    }

    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: const Color(0xFF667EEA),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: listPost.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PostCard(
              detailsModel: listPost[index],
              userModel: widget.userModel,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class EmptyPostsWidget extends StatelessWidget {
  const EmptyPostsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.news,
              size: 60.sp,
              color: const Color(0xFF667EEA),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Chưa có bài viết nào',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Hãy bắt đầu chia sẻ những khoảnh khắc của bạn',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}