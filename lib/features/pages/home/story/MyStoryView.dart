import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/server/story/StoryApi.dart';
import 'package:video_player/video_player.dart';
import '../../../../data/models/StoryModel/UserStoryGroup.dart';

class MyStoryView extends StatefulWidget {
  final UserStoryGroup userStory;
  final int initialIndex;

  const MyStoryView({
    Key? key,
    required this.userStory,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MyStoryView> createState() => _MyStoryViewState();
}

class _MyStoryViewState extends State<MyStoryView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;

  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPaused = false;
  bool _isNavigating = false; // ✅ Prevent multiple navigation calls
  Map<String,List<UserModel>> listUser = {};
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _getViewer();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 15), // Default duration
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextStory();
      }
    });

    _initializeStory(_currentIndex);
  }
  Future<void> _getViewer() async{
    for(var story in widget.userStory.stories){
      final listData = await StoryApi.getViewStory(story.detailsStory.storyModel.idStory);
      listUser[story.detailsStory.storyModel.idStory] = listData;
    }

  }
  Future<void> _initializeStory(int index) async {
    // Dispose previous video
    await _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _progressController.reset();

    if (!mounted) return;

    setState(() {});

    final story = widget.userStory.stories[index];

    // Initialize video
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(story.detailsStory.storyModel.url),
    );

    try {
      await _videoController!.initialize();

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
      });

      // Set progress duration based on video duration
      final duration = _videoController!.value.duration;
      _progressController.duration = duration;

      // Play video and start progress
      _videoController!.play();
      _progressController.forward();

      // ✅ Removed video listener - only use progress controller
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _goToNextStory() {
    // ✅ Prevent multiple calls during navigation
    if (_isNavigating) return;

    if (_currentIndex < widget.userStory.stories.length - 1) {
      // Còn story tiếp theo
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _initializeStory(_currentIndex);
    } else {
      // Đã xem hết story, quay về trang trước
      _isNavigating = true;
      if (mounted) {
        // ✅ Use post-frame callback to avoid navigation during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  void _goToPreviousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _initializeStory(_currentIndex);
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _videoController?.pause();
        _progressController.stop();
      } else {
        _videoController?.play();
        _progressController.forward();
      }
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;

          if (tapPosition < screenWidth * 0.3) {
            // Tap on left side - previous story
            _goToPreviousStory();
          } else if (tapPosition > screenWidth * 0.7) {
            // Tap on right side - next story
            _goToNextStory();
          } else {
            // Tap in middle - pause/play
            _togglePause();
          }
        },
        child: Stack(
          children: [
            // Video Player
            PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.userStory.stories.length,
              itemBuilder: (context, index) {
                if (index != _currentIndex) {
                  return Container(color: Colors.black);
                }

                if (!_isVideoInitialized || _videoController == null) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }

                return Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                );
              },
            ),

            // Progress bars at top
            SafeArea(
              child: Column(
                children: [
                  _buildProgressBars(),
                  _buildHeader(),
                ],
              ),
            ),

            // Reply input at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildReplyInput(),
            ),

            // Pause indicator
            if (_isPaused)
              Center(
                child: Icon(
                  Icons.pause_circle_outline,
                  color: Colors.white.withOpacity(0.5),
                  size: 80.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: List.generate(
          widget.userStory.stories.length,
              (index) {
            return Expanded(
              child: Container(
                height: 2.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1.r),
                ),
                child: index < _currentIndex
                    ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.r),
                  ),
                )
                    : index == _currentIndex
                    ? AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      ),
                    );
                  },
                )
                    : SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                widget.userStory.user.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: Icon(Icons.person, color: Colors.white),
                  );
                },
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // Username and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userStory.user.userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getTimeAgo(
                      widget.userStory.stories[_currentIndex].detailsStory.storyModel.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          // More options
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {
              // Show options
            },
          ),

          // Close button
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).padding.bottom + 16.h,
        top: 16.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showViewersBottomSheet,
            child: Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: Icon(
                Icons.visibility,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }
  void _showViewersBottomSheet() {
    final key = listUser.keys.elementAt(_currentIndex);
    print('key: $key');
    final list = listUser[key];
    // Pause video when showing bottom sheet
    setState(() {
      _isPaused = true;
      _videoController?.pause();
      _progressController.stop();
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 10.h),
                    height: 4.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Người xem',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          list!.length.toString(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),
                  Divider(height: 1),

                  // Viewers list
                  Expanded(
                    child: _buildViewersList(scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Resume video when bottom sheet is closed
      if (mounted) {
        setState(() {
          _isPaused = false;
          _videoController?.play();
          _progressController.forward();
        });
      }
    });
  }

  Widget _buildViewersList(ScrollController scrollController) {
    final key = listUser.keys.elementAt(_currentIndex);
    print('key: $key');
    final list = listUser[key];

    if (list!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Chưa có người xem', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: list.length,
      itemBuilder: (context, index) {
        final viewer = list[index]; // UserModel

        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(viewer.avatarUrl),
          ),
          title: Text(
            viewer.userName,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    _isNavigating = true; // ✅ Prevent any pending callbacks
    _progressController.stop();
    _progressController.dispose();
    _pageController.dispose();
    _videoController?.pause();
    _videoController?.dispose();
    super.dispose();
  }
}