import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import '../../../../data/models/StoryModel/UserStoryGroup.dart';

class StoryViewerPage extends StatefulWidget {
  final UserStoryGroup userStory;
  final int initialIndex;

  const StoryViewerPage({
    Key? key,
    required this.userStory,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;

  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPaused = false;
  bool _isNavigating = false;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    // Set fullscreen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isNavigating) {
        _goToNextStory();
      }
    });

    _initializeStory(_currentIndex);
  }

  Future<void> _initializeStory(int index) async {
    if (_isNavigating) return;

    // Dispose previous video
    _videoController?.pause();
    await _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _progressController.reset();

    if (!mounted) return;

    setState(() {});

    final story = widget.userStory.stories[index];

    // Initialize video with network optimization
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(story.detailsStory.storyModel.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _videoController!.initialize();

      if (!mounted || _isNavigating) return;

      setState(() {
        _isVideoInitialized = true;
      });

      final duration = _videoController!.value.duration;
      _progressController.duration = duration;

      // Start playback
      await _videoController!.play();
      _progressController.forward();
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted && !_isNavigating) {
        _goToNextStory();
      }
    }
  }

  void _goToNextStory() {
    if (_isNavigating) return;

    if (_currentIndex < widget.userStory.stories.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      _initializeStory(_currentIndex);
    } else {
      _closeViewer();
    }
  }

  void _goToPreviousStory() {
    if (_isNavigating) return;

    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      _initializeStory(_currentIndex);
    }
  }

  void _togglePause() {
    if (_isNavigating) return;

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

  void _closeViewer() {
    if (_isNavigating) return;
    _isNavigating = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
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
            _goToPreviousStory();
          } else if (tapPosition > screenWidth * 0.7) {
            _goToNextStory();
          } else {
            _togglePause();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Player
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.userStory.stories.length,
              itemBuilder: (context, index) {
                if (index != _currentIndex) {
                  return const SizedBox.shrink();
                }

                if (!_isVideoInitialized || _videoController == null) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.8),
                      strokeWidth: 2,
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

            // Gradient overlays for better readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top UI
            SafeArea(
              child: Column(
                children: [
                  _buildProgressBars(),
                  SizedBox(height: 12.h),
                  _buildHeader(),
                ],
              ),
            ),

            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Reply input at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildReplyInput(),
              ),
            ),

            // Pause indicator
            if (_isPaused)
              Center(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: 40.sp,
                  ),
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
                height: 3.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: index < _currentIndex
                      ? Container(color: Colors.white)
                      : index == _currentIndex
                      ? AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressController.value,
                        child: Container(color: Colors.white),
                      );
                    },
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                widget.userStory.user.avatarUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Username and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userStory.user.userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  _getTimeAgo(widget.userStory.stories[_currentIndex]
                      .detailsStory.storyModel.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _closeViewer,
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: TextField(
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Send message',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Like story
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 26.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Share story
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 26.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    _isNavigating = true;
    _progressController.stop();
    _progressController.dispose();
    _pageController.dispose();
    _videoController?.pause();
    _videoController?.dispose();
    super.dispose();
  }
}