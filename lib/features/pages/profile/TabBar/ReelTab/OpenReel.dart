import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:socialnetwork/data/models/ReelModel/ReelModel.dart';
import 'package:socialnetwork/data/models/userModel.dart';

class OpenReel extends StatefulWidget {
  final UserModel userModel;
  final ReelModel reelModel;

  const OpenReel({
    Key? key,
    required this.userModel,
    required this.reelModel,
  }) : super(key: key);

  @override
  State<OpenReel> createState() => _OpenReelState();
}

class _OpenReelState extends State<OpenReel> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPaused = false;
  bool _isMuted = false;

  // Animation for like
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _showLikeAnimation = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    // Initialize like animation
    _likeAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _likeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.reelModel.urlReel),
    );

    try {
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Auto play and loop
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    } catch (e) {
      print('❌ Error initializing video: $e');
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPaused = true;
      } else {
        _videoController!.play();
        _isPaused = false;
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _handleDoubleTap() {
    // Show like animation
    setState(() {
      _showLikeAnimation = true;
    });

    _likeAnimationController.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showLikeAnimation = false;
          });
          _likeAnimationController.reset();
        }
      });
    });

    // TODO: Call API to like reel
    print('Liked reel: ${widget.reelModel.reelId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player
          _buildVideoPlayer(),

          // Gradient overlays
          _buildGradientOverlays(),

          // Top bar
          _buildTopBar(),

          // Right side actions
          _buildRightActions(),

          // Bottom info
          _buildBottomInfo(),

          // Pause indicator
          if (_isPaused) _buildPauseIndicator(),

          // Like animation
          if (_showLikeAnimation) _buildLikeAnimation(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _handleDoubleTap,
      child: Center(
        child: _isVideoInitialized
            ? AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        )
            : Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlays() {
    return Column(
      children: [
        // Top gradient
        Container(
          height: 100.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Spacer(),
        // Bottom gradient
        Container(
          height: 200.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),

              Spacer(),

              // Mute button
              GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightActions() {
    return Positioned(
      right: 12.w,
      bottom: 120.h,
      child: Column(
        children: [
          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            label: _formatNumber(widget.reelModel.likeCount),
            onTap: _handleDoubleTap,
          ),

          SizedBox(height: 20.h),

          // Comment button
          _buildActionButton(
            icon: Icons.comment,
            label: _formatNumber(widget.reelModel.commentCount),
            onTap: () {
              // TODO: Open comment bottom sheet
              print('Open comments');
            },
          ),

          SizedBox(height: 20.h),

          // Share button
          _buildActionButton(
            icon: Icons.send,
            label: _formatNumber(widget.reelModel.sharesCount),
            onTap: () {
              // TODO: Share reel
              print('Share reel');
            },
          ),

          SizedBox(height: 20.h),

          // More options
          _buildActionButton(
            icon: Icons.more_vert,
            label: '',
            onTap: () {
              // TODO: Show more options
              print('More options');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          if (label.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 70.w,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.userModel.avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // Username
                  Text(
                    widget.userModel.userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Follow button (if not own reel)
                  if (widget.userModel.id != widget.reelModel.userId)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Theo dõi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Caption
              if (widget.reelModel.content.isNotEmpty &&
                  widget.reelModel.content != '0') ...[
                SizedBox(height: 12.h),
                Text(
                  widget.reelModel.content,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseIndicator() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.pause,
          color: Colors.white,
          size: 50.sp,
        ),
      ),
    );
  }

  Widget _buildLikeAnimation() {
    return Center(
      child: ScaleTransition(
        scale: _likeAnimation,
        child: Icon(
          Icons.favorite,
          color: Colors.white,
          size: 120.sp,
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }
}