import 'dart:convert';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:socialnetwork/data/models/PostModel/ArticleModel.dart';
import 'package:socialnetwork/data/models/PostModel/DetailsComment.dart';
import 'package:socialnetwork/data/models/PostModel/DetailsModel.dart';
import 'package:socialnetwork/data/server/postApi/PostApi.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widget/TextBasic.dart';
import '../../../data/models/PostModel/MediaItem.dart';
import '../../../data/models/userModel.dart';
import '../../../data/server/ServerConfig.dart';

class PostCard extends StatefulWidget {
  final DetailsModel detailsModel;
  final UserModel userModel;
  const PostCard({
    super.key,
    required this.detailsModel,
    required this.userModel,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PageController _pageController = PageController();
  TextEditingController _commentController = TextEditingController();
  int likeCount = 0;
  int commentCount = 0;
  int shareCount = 0;
  int repostCount = 0;
  int _currentPage = 0;
  bool _isLiked = false;
  bool _isShared = false;
  bool _isSaved = false;
  final player = AudioPlayer();
  bool _isPlay = false;
  // Video controllers map
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};
  Map<String, dynamic> music = {};
  List<DetailsComment> listComment = [];
  StreamSubscription<PlayerState>? _playerStateSub;
  @override
  void initState() {
    super.initState();
    _initializeCurrentPage();
    getMusicById();
    _playerStateSub = player.playerStateStream.listen((state) async {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        try {
          await player.seek(Duration.zero);
          await player.play();
        } catch (e) {
          debugPrint('Audio replay error: $e');
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _precacheAdjacentImages();
        getComment();
      }
    });
    setUpParameter();
  }

  // Chỉ initialize video hiện tại và adjacent pages
  void _initializeCurrentPage() {
    _initializeVideoAtIndex(_currentPage);
    // Preload adjacent videos
    if (_currentPage > 0) {
      _initializeVideoAtIndex(_currentPage - 1);
    }
    if (_currentPage < widget.detailsModel.articleModel.mediaItems.length - 1) {
      _initializeVideoAtIndex(_currentPage + 1);
    }
  }

  void _initializeVideoAtIndex(int index) {
    if (index < 0 ||
        index >= widget.detailsModel.articleModel.mediaItems.length)
      return;
    if (widget.detailsModel.articleModel.mediaItems[index].type != 'video')
      return;
    if (_videoControllers.containsKey(index)) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.detailsModel.articleModel.mediaItems[index].url),
    );
    _videoControllers[index] = controller;
    _videoInitialized[index] = false;

    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _videoInitialized[index] = true;
        });
        // Auto play if it's the current page
        if (index == _currentPage) {
          controller.play();
          controller.setLooping(true);
        }
      }
    });
  }

  // Precache ảnh của trang hiện tại và adjacent
  void _precacheAdjacentImages() {
    _precacheImageAtIndex(_currentPage);
    if (_currentPage > 0) {
      _precacheImageAtIndex(_currentPage - 1);
    }
    if (_currentPage < widget.detailsModel.articleModel.mediaItems.length - 1) {
      _precacheImageAtIndex(_currentPage + 1);
    }
  }

  void _precacheImageAtIndex(int index) {
    if (!mounted) return;
    if (index < 0 ||
        index >= widget.detailsModel.articleModel.mediaItems.length)
      return;
    if (widget.detailsModel.articleModel.mediaItems[index].type != 'image')
      return;

    final imageProvider = NetworkImage(
      widget.detailsModel.articleModel.mediaItems[index].url,
    );

    precacheImage(imageProvider, context).catchError((error) {
      debugPrint('Error precaching image at index $index: $error');
    });
  }

  void _onPageChanged(int index) {
    // Pause all videos
    _videoControllers.forEach((key, controller) {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
      }
    });

    // Play current video if exists
    if (_videoControllers.containsKey(index)) {
      final controller = _videoControllers[index]!;
      if (controller.value.isInitialized) {
        controller.play();
        controller.setLooping(true);
      }
    }

    setState(() {
      _currentPage = index;
    });

    // Preload adjacent pages
    _initializeVideoAtIndex(index - 1);
    _initializeVideoAtIndex(index + 1);
    _precacheImageAtIndex(index - 1);
    _precacheImageAtIndex(index + 1);

    // Dispose videos that are too far away (memory optimization)
    _disposeDistantVideos(index);
  }

  void _disposeDistantVideos(int currentIndex) {
    final keysToRemove = <int>[];
    _videoControllers.forEach((key, controller) {
      // Dispose videos that are more than 2 pages away
      if ((key - currentIndex).abs() > 2) {
        controller.dispose();
        keysToRemove.add(key);
      }
    });

    for (var key in keysToRemove) {
      _videoControllers.remove(key);
      _videoInitialized.remove(key);
    }
  }

  Future<void> getMusicById() async {
    if (widget.detailsModel.articleModel.idMusic == '0') return;
    final String response = await rootBundle.loadString(
      'assets/data/songs.json',
    );
    final List songs = jsonDecode(response);
    for (var song in songs) {
      if (song['id'] == widget.detailsModel.articleModel.idMusic) {
        await player.setUrl(song['file']);
        if (!mounted) return;
        setState(() {
          music = {
            "id": song['id'],
            "name": song['name'],
            "author": song['author'],
            "avatar": song['avatar'],
            "file": song['file'],
          };
        });
        break;
      }
    }
  }

  Future<void> getComment() async {
    final List<DetailsComment> listGetApi = await PostApi.getComment(
      widget.detailsModel.articleModel.articleID,
    );
    if (!mounted) return;
    if (listGetApi.isNotEmpty) {
      setState(() {
        listComment = listGetApi;
      });
    }
  }

  void setUpParameter() {
    likeCount = widget.detailsModel.articleModel.likeCount;
    commentCount = widget.detailsModel.articleModel.commentCount;
    shareCount = widget.detailsModel.articleModel.sharesCount;
    repostCount = widget.detailsModel.articleModel.repostCount;
    _isLiked = widget.detailsModel.isLiked;
    _isShared = widget.detailsModel.isShared;
    _isSaved = widget.detailsModel.isRePosted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildMediaCarousel(),
        _buildActions(context),
        _buildLikesAndCaption(),
        Divider(height: 1.h, thickness: 0.5, color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFCAF45),
                  Color(0xFFE1306C),
                  Color(0xFFC13584),
                  Color(0xFF833AB4),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 16.r,
                backgroundImage: CachedNetworkImageProvider(
                  widget.detailsModel.userModel.avatarUrl,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.detailsModel.userModel.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                if (widget.detailsModel.articleModel.idMusic != '0')
                  Row(
                    children: [
                      Icon(Icons.music_note, size: 10.sp),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${music['name'] ?? '...'}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCarousel() {
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.width * 1.25,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.detailsModel.articleModel.mediaItems.length,
            itemBuilder: (context, index) {
              final item = widget.detailsModel.articleModel.mediaItems[index];
              return Container(
                color: Colors.black,
                child: item.type == 'image'
                    ? Image.network(
                        item.url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 40.sp,
                            ),
                          );
                        },
                      )
                    : _buildVideoPlayer(index),
              );
            },
          ),
        ),

        // Dots indicator
        if (widget.detailsModel.articleModel.mediaItems.length > 1)
          Positioned(
            top: 8.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.detailsModel.articleModel.mediaItems.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  width: index == _currentPage ? 24.w : 6.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(1.r),
                  ),
                ),
              ),
            ),
          ),
        if (widget.detailsModel.articleModel.idMusic != '0')
          Positioned(
            bottom: 5,
            right: 0,
            child: GestureDetector(
              onTap: () {
                if (_isPlay) {
                  _pauseMusic();
                } else {
                  _playMusic();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 5.w),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(36.r),
                ),
                child: _isPlay
                    ? Icon(Icons.volume_up, color: Colors.white)
                    : Icon(Icons.volume_off, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _videoControllers[index];
    final isInitialized = _videoInitialized[index] ?? false;

    if (controller == null || !isInitialized) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (controller.value.isPlaying) {
            controller.pause();
          } else {
            controller.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          // Play/Pause icon overlay
          if (!controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(12.w),
              child: Icon(Icons.play_arrow, color: Colors.white, size: 48.sp),
            ),
          // Mute/Unmute button
          Positioned(
            bottom: 16.h,
            right: 16.w,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  controller.setVolume(controller.value.volume > 0 ? 0.0 : 1.0);
                });
              },
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.value.volume > 0
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              PostApi.likeAndeDislike(
                widget.detailsModel.articleModel.articleID,
                widget.userModel.id,
              );
              if (_isLiked) {
                setState(() {
                  _isLiked = !_isLiked;
                  likeCount--;
                });
              } else {
                setState(() {
                  _isLiked = !_isLiked;
                  likeCount++;
                });
              }
            },
            child: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.black,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            _formatNumber(likeCount),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
          ),
          SizedBox(width: 16.w),
          GestureDetector(
            onTap: () {
              _openPopup(context, widget.userModel);
            },
            child: FaIcon(FontAwesomeIcons.comment),
          ),
          SizedBox(width: 2.w),
          Text(
            _formatNumber(commentCount),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
          ),
          SizedBox(width: 16.w),
          GestureDetector(
            onTap: () async {
              await _handleShare(
                widget.detailsModel.articleModel.articleID,
                widget.userModel.id,
              );
            },
            child: FaIcon(
              FontAwesomeIcons.paperPlane,
              color: _isShared ? Colors.blue : Colors.black,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            _formatNumber(shareCount),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
          ),
          const Spacer(),
          Text(
            _formatNumber(repostCount),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () async {
              await _handleRepost(
                widget.detailsModel.articleModel.articleID,
                widget.userModel.id,
              );
            },
            child: FaIcon(
              FontAwesomeIcons.repeat,
              size: 20.sp,
              color: _isSaved ? Colors.yellow : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesAndCaption() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.detailsModel.articleModel.content != '0') ...[
            SizedBox(height: 4.h),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 14.sp),
                children: [
                  TextSpan(
                    text: '${widget.detailsModel.userModel.userName}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: widget.detailsModel.articleModel.content),
                ],
              ),
            ),
          ],
        ],
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

  Future<void> _playMusic() async {
    try {
      print('🎵 Đang phát');
      if (!mounted) return;
      setState(() {
        _isPlay = true;
      });
      try {
        await player.play();
      } catch (e) {
        debugPrint('❌ Lỗi phát audio (play): $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể phát nhạc. Vui lòng thử lại!'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isPlay = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi phát nhạc: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể phát nhạc. Vui lòng thử lại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tạm dừng nhạc
  Future<void> _pauseMusic() async {
    try {
      print('⏸️ Tạm dừng nhạc');
      if (!mounted) return;
      setState(() {
        _isPlay = false;
      });
      player.pause();
    } catch (e) {
      print('❌ Lỗi khi tạm dừng: $e');
    }
  }

  void _openPopup(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // ✅ Cho phép đóng khi tap ra ngoài
      enableDrag: true, // ✅ Cho phép kéo xuống để đóng
      builder: (context) {
        return GestureDetector(
          onTap: () {
            // ✅ Đóng bàn phím khi tap vào vùng trống
            FocusScope.of(context).unfocus();
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(
                    context,
                  ).viewInsets.bottom, // ✅ Đẩy lên khi bàn phím hiện
                ),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.65,
                  minChildSize: 0.4,
                  maxChildSize: 0.95,
                  builder: (_, controller) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            height: 4,
                            width: 45,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),

                          SizedBox(height: 12),
                          Text(
                            "Bình luận",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 12),

                          Divider(height: 1, color: Colors.grey.shade300),

                          /// LIST COMMENT
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // ✅ Đóng bàn phím khi tap vào list
                                FocusScope.of(context).unfocus();
                              },
                              child: ListView.builder(
                                controller: controller,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior
                                        .onDrag, // ✅ Đóng bàn phím khi scroll
                                itemCount: listComment.length,
                                itemBuilder: (context, index) {
                                  final item = listComment[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                item.user.avatarUrl,
                                              ),
                                        ),
                                        SizedBox(width: 10),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    item.user.userName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    "• ${timeAgo(item.createAt)}",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Text(item.content),
                                            ],
                                          ),
                                        ),

                                        Icon(Icons.favorite_border, size: 18),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          /// Khung nhập bình luận
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: SafeArea(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18.r,
                                    backgroundImage: CachedNetworkImageProvider(
                                      user.avatarUrl,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      textInputAction: TextInputAction
                                          .send, // ✅ Nút send trên bàn phím
                                      maxLines: null, // ✅ Cho phép nhiều dòng
                                      keyboardType: TextInputType.multiline,
                                      decoration: InputDecoration(
                                        hintText: "Bình luận...",
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 8.h,
                                        ),
                                      ),
                                      onSubmitted: (value) async {
                                        // ✅ Xử lý khi nhấn send trên bàn phím
                                        await _handleSendComment(
                                          context,
                                          setModalState,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  GestureDetector(
                                    onTap: () async {
                                      await _handleSendComment(
                                        context,
                                        setModalState,
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      child: Icon(
                                        Icons.send,
                                        color:
                                            _commentController.text
                                                .trim()
                                                .isEmpty
                                            ? Colors.grey
                                            : Colors.blue,
                                        size: 24.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleSendComment(
    BuildContext context,
    StateSetter setModalState,
  ) async {
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập bình luận'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Đóng bàn phím
    FocusScope.of(context).unfocus();

    final detailsComment = DetailsComment(
      user: widget.userModel,
      content: content,
      createAt: DateTime.now(),
    );

    // Update UI ngay lập tức
    if (!mounted) return;
    setState(() {
      commentCount++;
      listComment = [detailsComment, ...listComment];
      _commentController.clear();
    });

    setModalState(() {
      // Trigger rebuild modal
    });

    // Gọi API
    final result = await PostApi.comment(
      widget.detailsModel.articleModel.articleID,
      widget.userModel.id,
      content,
    );

    if (!result && mounted) {
      setState(() {
        commentCount--;
        if (listComment.isNotEmpty) {
          listComment.removeAt(0);
        }
      });

      setModalState(() {});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi trong lúc bình luận vui lòng thử lại sau!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleShare(String postId, String userId) async {
    final url = '${ServerConfig.baseUrl}/post/$postId';
    Clipboard.setData(ClipboardData(text: url));

    if (!mounted) return;
    if (_isShared) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã hủy share")));
      setState(() {
        shareCount--;
        _isShared = false;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã copy vào clipboard")));
      setState(() {
        shareCount++;
        _isShared = true;
      });
    }
    final result = await PostApi.share(postId, userId);
    if (!result && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi hệ thống'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleRepost(String postId, String userId) async {
    if (!mounted) return;
    if (_isSaved) {
      setState(() {
        repostCount--;
        _isSaved = false;
      });
    } else {
      setState(() {
        repostCount++;
        _isSaved = true;
      });
    }
    final result = await PostApi.repost(
      widget.detailsModel.articleModel.articleID,
      widget.userModel.id,
    );
    if (!result && mounted) {
      setState(() {
        repostCount--;
        _isSaved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi hệ thống'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    // Dưới 1 phút
    if (diff.inMinutes < 1) return 'Vừa xong';

    // Dưới 60 phút → phút
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';

    // Dưới 24 giờ → giờ
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';

    // Dưới 30 ngày → ngày
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';

    // Tháng: 1 tháng = 30 ngày (ước lượng chuẩn trong UX)
    final months = diff.inDays ~/ 30;
    if (months < 12) return '$months tháng trước';

    // Năm
    final years = months ~/ 12;
    return '$years năm trước';
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all video controllers
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
    _playerStateSub?.cancel();
    player.dispose();
    super.dispose();
  }
}
