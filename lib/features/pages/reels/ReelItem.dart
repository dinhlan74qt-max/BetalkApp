import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:socialnetwork/data/models/PostModel/DetailsComment.dart';
import 'package:socialnetwork/data/models/ReelModel/DetailsReelModel.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/server/reelApi/ReelApi.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelItem extends StatefulWidget {
  final DetailsReelModel reel;
  final UserModel userModel;
  final bool isActive;
  final int currentPage;
  final int itemIndex;
  final List<DetailsComment> cachedComments;
  final Map<String, dynamic> cachedState;
  final Function(List<DetailsComment>) onCommentsChanged;
  final Function(Map<String, dynamic>) onStateChanged;

  const ReelItem({
    super.key,
    required this.reel,
    required this.isActive,
    required this.userModel,
    required this.currentPage,
    required this.itemIndex,
    required this.cachedComments,
    required this.cachedState,
    required this.onCommentsChanged,
    required this.onStateChanged,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> with AutomaticKeepAliveClientMixin {
  TextEditingController _commentController = TextEditingController();
  late List<DetailsComment> listComment;
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  late bool _isLiked;
  late bool _isShared;
  late bool _isSaved;
  late int _likeCount;
  late int _shareCount;
  late int _commentCount;
  late int _repostCount;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // ✅ Load từ cache
    _loadFromCache();
    _initializeVideo();
    // ✅ Load comments nếu chưa có
    if (listComment.isEmpty) {
      _loadComments();
    }
  }

  void _loadFromCache() {
    listComment = List.from(widget.cachedComments);
    _isLiked = widget.cachedState['isLiked'] ?? widget.reel.isLiked;
    _isShared = widget.cachedState['isShared'] ?? widget.reel.isShared;
    _isSaved = widget.cachedState['isSaved'] ?? widget.reel.isRePosted;
    _likeCount = widget.cachedState['likeCount'] ?? widget.reel.reelModel.likeCount;
    _shareCount = widget.cachedState['shareCount'] ?? widget.reel.reelModel.sharesCount;
    _commentCount = widget.cachedState['commentCount'] ?? widget.reel.reelModel.commentCount;
    _repostCount = widget.cachedState['repostCount'] ?? widget.reel.reelModel.repostCount;
  }

  Future<void> _loadComments() async {
    final comments = await ReelApi.getComment(widget.reel.reelModel.reelId);
    if (mounted) {
      setState(() {
        listComment = comments;
      });
      widget.onCommentsChanged(comments);
    }
  }

  void _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel.reelModel.urlReel),
    );

    await _controller.initialize();
    _controller.setLooping(true);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });

      // ✅ Auto play nếu là video hiện tại hoặc adjacent
      final distance = (widget.itemIndex - widget.currentPage).abs();
      if (distance <= 1) {
        if (widget.isActive) {
          _controller.play();
        }
      }
    }
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Update từ cache khi widget update
    if (widget.cachedComments != oldWidget.cachedComments) {
      setState(() {
        listComment = List.from(widget.cachedComments);
      });
    }

    if (widget.cachedState != oldWidget.cachedState) {
      _loadFromCache();
    }

    // ✅ Control video playback
    if (widget.isActive && !oldWidget.isActive) {
      _controller.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.pause();
    }

    // ✅ Preload adjacent videos
    final distance = (widget.itemIndex - widget.currentPage).abs();
    if (distance <= 1 && !_isInitialized) {
      _initializeVideo();
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _updateState() {
    widget.onStateChanged({
      'isLiked': _isLiked,
      'isShared': _isShared,
      'isSaved': _isSaved,
      'likeCount': _likeCount,
      'shareCount': _shareCount,
      'commentCount': _commentCount,
      'repostCount': _repostCount,
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.w,
                ),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          if (!_controller.value.isPlaying && _isInitialized)
            Center(
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30.sp,
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 85.w,
            child: _buildBottomSection(),
          ),

          Positioned(right: 12.w, bottom: 100.h, child: _buildRightActions()),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.w),
                ),
                child: CircleAvatar(
                  radius: 18.r,
                  backgroundImage:
                  CachedNetworkImageProvider(widget.reel.userModel.avatarUrl),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                widget.reel.userModel.userName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 12.w),
            ],
          ),
          if (widget.reel.reelModel.content != '0') ...[
            SizedBox(height: 12.h),
            Text(
              widget.reel.reelModel.content,
              style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRightActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          _isLiked
              ? FaIcon(size: 25.sp, FontAwesomeIcons.solidHeart, color: Colors.red)
              : FaIcon(size: 25.sp, FontAwesomeIcons.heart, color: Colors.white),
          _likeCount.toString(),
          onTap: () {
            _handleLike(widget.reel.reelModel.reelId, widget.userModel.id);
          },
        ),
        SizedBox(height: 14.h),
        _buildActionButton(
          FaIcon(FontAwesomeIcons.comment, size: 25.sp, color: Colors.white),
          _commentCount.toString(),
          onTap: () {
            _openPopup(context, widget.userModel);
          },
        ),
        SizedBox(height: 14.h),
        _buildActionButton(
          FaIcon(
            FontAwesomeIcons.paperPlane,
            size: 20.sp,
            color: _isShared ? Colors.blue : Colors.white,
          ),
          _shareCount.toString(),
          onTap: () {
            _handleShare(widget.reel.reelModel.reelId, widget.userModel.id);
          },
        ),
        SizedBox(height: 14.h),
        _buildActionButton(
          FaIcon(
            FontAwesomeIcons.repeat,
            size: 20.sp,
            color: _isSaved ? Colors.yellow : Colors.white,
          ),
          _repostCount.toString(),
          onTap: () {
            _handleRepost(widget.reel.reelModel.reelId, widget.userModel.id);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(Widget icon, String count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          icon,
          SizedBox(height: 4.h),
          Text(
            count,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: Offset(0, 1.h),
                  blurRadius: 2.r,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPopup(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.65,
                  minChildSize: 0.4,
                  maxChildSize: 0.95,
                  builder: (_, controller) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
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
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade300),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                              },
                              child: ListView.builder(
                                controller: controller,
                                keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: listComment.length,
                                itemBuilder: (context, index) {
                                  final item = listComment[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage:
                                          CachedNetworkImageProvider(
                                              item.user.avatarUrl),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(item.user.userName,
                                                      style: TextStyle(
                                                          fontWeight:
                                                          FontWeight.w600)),
                                                  SizedBox(width: 5),
                                                  Text(
                                                      "• ${timeAgo(item.createAt)}",
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                          Colors.grey[600])),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Text(item.content),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.favorite_border, size: 18)
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
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
                                        user.avatarUrl),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: TextField(
                                      controller: _commentController,
                                      textInputAction: TextInputAction.send,
                                      maxLines: null,
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
                                        color: _commentController.text
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
                          )
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
      BuildContext context, StateSetter setModalState) async {
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

    FocusScope.of(context).unfocus();

    final detailsComment = DetailsComment(
      user: widget.userModel,
      content: content,
      createAt: DateTime.now(),
    );

    setState(() {
      _commentCount++;
      listComment = [detailsComment, ...listComment];
      _commentController.clear();
    });

    // ✅ Update cache
    widget.onCommentsChanged(listComment);
    _updateState();

    setModalState(() {});

    final result = await ReelApi.comment(
        widget.userModel.id, widget.reel.reelModel.reelId, content);

    if (!result) {
      setState(() {
        _commentCount--;
        listComment.removeAt(0);
      });

      widget.onCommentsChanged(listComment);
      _updateState();
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

  Future<void> _handleLike(String reelId, String userId) async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    _updateState();

    final result = await ReelApi.likeReel(reelId, userId);
    if (!result) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      _updateState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi hệ thống'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleShare(String reelId, String userId) async {
    setState(() {
      _isShared = !_isShared;
      _shareCount += _isShared ? 1 : -1;
    });
    _updateState();

    final result = await ReelApi.shareReel(reelId, userId);
    if (!result) {
      setState(() {
        _isShared = !_isShared;
        _shareCount += _isShared ? 1 : -1;
      });
      _updateState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi hệ thống'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleRepost(String reelId, String userId) async {
    setState(() {
      _isSaved = !_isSaved;
      _repostCount += _isSaved ? 1 : -1;
    });
    _updateState();

    final result = await ReelApi.repostReel(reelId, userId);
    if (!result) {
      setState(() {
        _isSaved = !_isSaved;
        _repostCount += _isSaved ? 1 : -1;
      });
      _updateState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi hệ thống'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';

    final months = diff.inDays ~/ 30;
    if (months < 12) return '$months tháng trước';

    final years = months ~/ 12;
    return '$years năm trước';
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }
}