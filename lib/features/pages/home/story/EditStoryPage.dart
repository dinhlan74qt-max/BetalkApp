import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/server/story/StoryApi.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../../../../core/widget/Main_bottom_nav.dart';
import '../../../../core/widget/TextBasic.dart';
import '../../../../data/server/mediaApi/MediaApi.dart';

class EditStoryPage extends StatefulWidget {
  final AssetEntity selectedAsset;
  final UserModel userModel;
  const EditStoryPage({
    super.key,
    required this.selectedAsset,
    required this.userModel
  });

  @override
  State<EditStoryPage> createState() => _EditStoryPageState();
}

class _EditStoryPageState extends State<EditStoryPage> with TickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();

  Map<String, dynamic>? selectedSong;
  bool isPlaying = false;
  final player = AudioPlayer();

  bool _showCaption = false;
  String _selectedAudience = 'Công khai';

  late AnimationController _pulseController;
  late AnimationController _fadeController;

  // Video player
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isVideoInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkMediaType();

    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        player.seek(Duration.zero);
        player.play();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  Future<void> _checkMediaType() async {
    _isVideo = widget.selectedAsset.type == AssetType.video;

    if (_isVideo) {
      final file = await widget.selectedAsset.file;
      if (file != null) {
        _videoController = VideoPlayerController.file(file)
          ..initialize().then((_) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController!.setLooping(true);
            _videoController!.play();
          });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    player.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image/Video Preview with gradient overlay
          _buildMediaPreview(),

          // Vignette effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),

          // Top Bar
          _buildTopBar(),

          // Overlay Controls
          _buildOverlayControls(),

          // Bottom Bar
          _buildBottomBar(context),

          // Caption Input (when active)
          if (_showCaption) _buildCaptionInput(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_isVideo && _isVideoInitialized && _videoController != null) {
      return Positioned.fill(
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              // Play/Pause overlay
              if (!_videoController!.value.isPlaying)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 48.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Image preview
    return Positioned.fill(
      child: FutureBuilder<Uint8List?>(
        future: widget.selectedAsset.thumbnailDataWithSize(
          ThumbnailSize(1080, 1920),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            );
          }
          return Center(
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8.h,
          left: 16.w,
          right: 16.w,
          bottom: 16.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Close button with glassmorphism
            _buildGlassButton(
              icon: Icons.close_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                _videoController?.pause();
                Navigator.pop(context);
              },
            ),

            Spacer(),

            // Settings button
            _buildGlassButton(
              icon: Icons.tune_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                // Show settings
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap,}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildOverlayControls() {
    return Positioned(
      right: 10.w,
      top: MediaQuery.of(context).size.height * 0.15,
      child: Column(
        children: [
          // Text button
          _buildModernControlButton(
            icon: Icons.title_rounded,
            label: 'Text',
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showCaption = !_showCaption;
              });
            },
          ),


          // Music button
          if(_isVideo == false) ...[
            SizedBox(height: 20.h),
            _buildModernControlButton(
              icon: Icons.music_note_rounded,
              label: 'Music',
              gradient: LinearGradient(
                colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                _showMusicPicker(context);
              },
              badge: selectedSong != null,
            ),
          ],


          SizedBox(height: 20.h),

          // Sticker button
          _buildModernControlButton(
            icon: Icons.emoji_emotions_rounded,
            label: 'Sticker',
            gradient: LinearGradient(
              colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              // Show sticker picker
            },
          ),

          SizedBox(height: 20.h),

          // Draw button
          _buildModernControlButton(
            icon: Icons.brush_rounded,
            label: 'Draw',
            gradient: LinearGradient(
              colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              // Show drawing tools
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernControlButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              if (badge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 10.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext contaxt) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          bottom: MediaQuery.of(context).padding.bottom + 16.h,
          top: 20.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Music Player (if song selected)
            if (selectedSong != null) _buildModernMusicPlayer(),

            SizedBox(height: 16.h),

            // Bottom buttons
            Row(
              children: [
                // Audience selector
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showAudiencePicker();
                    },
                    child: Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getAudienceIcon(),
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _selectedAudience,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Share button with animation
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _shareStory(context);
                  },
                  child: Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF667EEA).withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAudienceIcon() {
    switch (_selectedAudience) {
      case 'Bạn bè':
        return Icons.people_rounded;
      case 'Chỉ mình tôi':
        return Icons.lock_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  Widget _buildModernMusicPlayer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 64.h,
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667EEA).withOpacity(0.3),
                Color(0xFF764BA2).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF667EEA).withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: isPlaying ? _pulseController.value * 2 : 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Album art with pulse effect
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667EEA).withOpacity(0.5),
                      blurRadius: isPlaying ? 12 + (_pulseController.value * 4) : 8,
                      spreadRadius: isPlaying ? _pulseController.value * 1.5 : 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: CachedNetworkImage(
                    imageUrl: selectedSong!['avatar'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                      ),
                      child: Icon(Icons.music_note_rounded, color: Colors.white, size: 22.sp),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      selectedSong!['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      selectedSong!['author'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Play/Pause button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isPlaying) {
                    _pauseMusic();
                  } else {
                    _playMusic(selectedSong!['file']);
                  }
                },
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              // Remove button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _stopMusic();
                  setState(() {
                    selectedSong = null;
                    isPlaying = false;
                  });
                },
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptionInput() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showCaption = false;
          });
          FocusScope.of(context).unfocus();
        },
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ).createShader(bounds),
                    child: Text(
                      'Add Caption',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Text field with modern design
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _captionController,
                      autofocus: true,
                      maxLines: 5,
                      maxLength: 150,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14.sp,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(
                            width: 2,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: EdgeInsets.all(14.w),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _captionController.clear();
                            setState(() {
                              _showCaption = false;
                            });
                          },
                          child: Container(
                            height: 46.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 10.w),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showCaption = false;
                            });
                            FocusScope.of(context).unfocus();
                          },
                          child: Container(
                            height: 46.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF667EEA).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
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
        ),
      ),
    );
  }

  void _showMusicPicker(BuildContext context) async {
    final listFile = await loadSongs();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 10.h),
                    height: 4.h,
                    width: 45.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ).createShader(bounds),
                    child: Text(
                      'Chọn nhạc',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                  // List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      itemCount: listFile.length,
                      itemBuilder: (context, index) {
                        final data = listFile[index];
                        final isSelected = selectedSong?['name'] == data['name'];

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                              colors: [
                                Color(0xFF667EEA).withOpacity(0.1),
                                Color(0xFF764BA2).withOpacity(0.1),
                              ],
                            )
                                : null,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            leading: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667EEA).withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child: CachedNetworkImage(
                                  imageUrl: data['avatar'],
                                  width: 52.w,
                                  height: 52.w,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              data['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                                color: isSelected ? Color(0xFF667EEA) : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              data['author'],
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: isSelected
                                ? Container(
                              width: 30.w,
                              height: 30.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            )
                                : null,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              setModalState(() {
                                selectedSong = data;
                                isPlaying = true;
                              });
                              setState(() {
                                selectedSong = data;
                              });
                              await _playMusic(data['file']);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAudiencePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ).createShader(bounds),
                child: Text(
                  'Share with',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              _buildAudienceOption('Công khai', Icons.public_rounded),
              _buildAudienceOption('Bạn bè', Icons.people_rounded),
              _buildAudienceOption('Chỉ mình tôi', Icons.lock_rounded),
              SizedBox(height: 6.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudienceOption(String title, IconData icon) {
    final isSelected = _selectedAudience == title;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [
            Color(0xFF667EEA).withOpacity(0.1),
            Color(0xFF764BA2).withOpacity(0.1),
          ],
        )
            : null,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
        leading: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            )
                : null,
            color: isSelected ? null : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[700],
            size: 22.sp,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
            color: isSelected ? Color(0xFF667EEA) : Colors.black87,
          ),
        ),
        trailing: isSelected
            ? Container(
          width: 26.w,
          height: 26.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 14.sp,
          ),
        )
            : null,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedAudience = title;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<List<dynamic>> loadSongs() async {
    final String response = await rootBundle.loadString('assets/data/songs.json');
    return jsonDecode(response);
  }

  Future<void> _playMusic(String musicUrl) async {
    try {
      await player.setUrl(musicUrl);
      setState(() {
        isPlaying = true;
        player.play();
      });
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> _pauseMusic() async {
    setState(() {
      isPlaying = false;
      player.pause();
    });
  }

  Future<void> _stopMusic() async {
    setState(() {
      isPlaying = false;
      player.stop();
    });
  }

  Future<void> _shareStory(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    try{
      if (_isVideo) {
        _videoController?.pause();
        File? videoFile = await widget.selectedAsset.file;
        final result = await MediaApi.uploadToServer(videoFile!);
        final url = result['url'];
        final uploadStory = await StoryApi.newStory(widget.userModel.id, url);
        if(uploadStory['success']){
          showStorySuccessDialog(context);
          final story = uploadStory['data'];
        }else{
          print(uploadStory['error']);
          showStoryErrorDialog(context, 'Có lỗi trong lúc đăng story. Vui lòng thử lại sau !');
        }

      } else {
        // Nếu chọn nhạc
        if (selectedSong != null) {
          File? imageFile = await widget.selectedAsset.file;
          final result = await MediaApi.createVideoFromImageAndAudio(
            imageFile!,
            selectedSong!['file'],
          );

          if (result['success']) {
            final uploadStory = await StoryApi.newStory(widget.userModel.id, result['videoUrl']);
            if(uploadStory['success']){
              showStorySuccessDialog(context);
              final story = uploadStory['data'];
            }else{
              print(uploadStory['error']);
              showStoryErrorDialog(context, 'Có lỗi trong lúc đăng story. Vui lòng thử lại sau !');
            }
          } else {
            print("Error: ${result['error']}");
            showStoryErrorDialog(context, 'Có lỗi trong lúc đăng story. Vui lòng thử lại sau !');
          }
        }else{
          File? imageFile = await widget.selectedAsset.file;
          final result = await MediaApi.createVideoFromImage(
            imageFile!,
          );
          if (result['success']) {
            final uploadStory = await StoryApi.newStory(widget.userModel.id, result['videoUrl']);
            if(uploadStory['success']){
              showStorySuccessDialog(context);
              final story = uploadStory['data'];
            }else{
              print(uploadStory['error']);
              showStoryErrorDialog(context, 'Có lỗi trong lúc đăng story. Vui lòng thử lại sau !');
            }
          } else {
            print("Error: ${result['error']}");
            showStoryErrorDialog(context, 'Có lỗi trong lúc đăng story. Vui lòng thử lại sau !');

          }
        }
      }
    }catch(e){
      print(e);
    }finally{
      setState(() {
        _isLoading = false;
      });
    }

    print('Share story - Type: ${_isVideo ? "Video" : "Image"}');
  }
  Future<void> showStorySuccessDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false, // không cho bấm ra ngoài để tắt
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Đăng story thành công",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Story của bạn đã được chia sẻ.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                    const MainNavigationScreen(initialIndex: 0,),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                              begin: const Offset(1.0, 0.0), end: Offset.zero),
                        ),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 800),
                  ),
                      (Route<dynamic> route) => false,
                ); // đóng popup
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );

    // Tự đóng sau 2.5 giây
    await Future.delayed(Duration(milliseconds: 2500));
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  Future<void> showStoryErrorDialog(BuildContext context, String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Lỗi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Đóng"),
            ),
          ],
        );
      },
    );

    // Tự đóng sau 2.5 giây
    await Future.delayed(Duration(milliseconds: 2500));
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }



}