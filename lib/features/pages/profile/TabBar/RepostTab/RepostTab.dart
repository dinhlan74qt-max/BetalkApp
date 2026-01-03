import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:socialnetwork/data/models/PostModel/RepostModel.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/ImageTab/OpenImage.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/ReelTab/OpenReel.dart';
import '../../../../../data/models/PostModel/ArticleModel.dart';
import '../../../../../data/models/ReelModel/ReelModel.dart';
import '../../../../../data/models/userModel.dart';

class RepostTab extends StatefulWidget {
  final UserModel userModel;
  final List<RepostModel> listRepostModel;

  const RepostTab({
    super.key,
    required this.userModel,
    required this.listRepostModel,
  });

  @override
  State<RepostTab> createState() => _RepostTabState();
}

class _RepostTabState extends State<RepostTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listRepostModel.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: Colors.grey[50],
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return GridView.builder(
            padding: EdgeInsets.all(2.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 2.w,
              childAspectRatio: 1.0,
            ),
            itemCount: widget.listRepostModel.length,
            itemBuilder: (context, index) {
              final repost = widget.listRepostModel[index];
              final delay = index * 0.05;
              final animation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    delay.clamp(0.0, 1.0),
                    (delay + 0.2).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                ),
              );

              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: _buildRepostItem(repost, index),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRepostItem(RepostModel repost, int index) {
    final type = repost.type.toLowerCase();

    if ((type == 'reel') && repost.reelModel != null) {
      return _buildReelItem(repost.reelModel!, index);
    } else if ((type == 'post' || type == 'article') && repost.article != null) {
      return _buildArticleItem(repost.article!, index);
    }

    return _buildPlaceholder();
  }

  Widget _buildReelItem(ReelModel reel, int index) {
    return GestureDetector(
      onTap: () {
        _openReelViewer(reel);
      },
      child: Hero(
        tag: 'repost_reel_${reel.reelId}_$index',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video thumbnail
                CachedNetworkImage(
                  imageUrl: _getVideoThumbnail(reel.urlReel),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[900]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[900]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ).createShader(bounds),
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.white,
                          size: 30.sp,
                        ),
                      ),
                    ),
                  ),
                ),

                // Dark gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.5),
                        ],
                        stops: const [0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),

                // Repost badge at top left
                Positioned(
                  top: 6.w,
                  left: 6.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4CAF50).withOpacity(0.9),
                          Color(0xFF66BB6A).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4CAF50).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.repeat,
                      color: Colors.white,
                      size: 10.sp,
                    ),
                  ),
                ),

                // Video icon at top right
                Positioned(
                  top: 6.w,
                  right: 6.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 12.sp,
                    ),
                  ),
                ),

                // View count at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                          ).createShader(bounds),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          _formatNumber(reel.likeCount),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tap overlay
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openReelViewer(reel),
                    splashColor: const Color(0xFF667EEA).withOpacity(0.2),
                    highlightColor: const Color(0xFF667EEA).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleItem(ArticleModel article, int index) {
    final firstMedia = article.mediaItems.isNotEmpty
        ? article.mediaItems.first
        : null;

    if (firstMedia == null || firstMedia.url.isEmpty) {
      return _buildPlaceholder();
    }

    return GestureDetector(
      onTap: () {
        _openPostDetail(article);
      },
      child: Hero(
        tag: 'repost_article_${article.articleID}_$index',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image/Video thumbnail
                CachedNetworkImage(
                  imageUrl: firstMedia.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[200]!,
                          Colors.grey[300]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[200]!,
                          Colors.grey[300]!,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey[400],
                      size: 30.sp,
                    ),
                  ),
                ),

                // Repost badge at top left
                Positioned(
                  top: 6.w,
                  left: 6.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4CAF50).withOpacity(0.9),
                          Color(0xFF66BB6A).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4CAF50).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.repeat,
                      color: Colors.white,
                      size: 10.sp,
                    ),
                  ),
                ),

                // Video indicator
                if (firstMedia.type == 'video')
                  Positioned(
                    top: 6.w,
                    right: 6.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 10.sp,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Multiple images indicator
                if (article.mediaItems.length > 1)
                  Positioned(
                    top: 6.w,
                    right: 6.w,
                    child: Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.layerGroup,
                        color: Colors.white,
                        size: 10.sp,
                      ),
                    ),
                  ),

                // Engagement overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (article.commentCount > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_rounded,
                                color: Colors.white,
                                size: 12.sp,
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                _formatNumber(article.commentCount),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                              ).createShader(bounds),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 12.sp,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              _formatNumber(article.likeCount),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tap overlay
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openPostDetail(article),
                    splashColor: const Color(0xFF667EEA).withOpacity(0.2),
                    highlightColor: const Color(0xFF667EEA).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
          size: 30.sp,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4CAF50).withOpacity(0.1),
                    Color(0xFF66BB6A).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ).createShader(bounds),
                  child: FaIcon(
                    FontAwesomeIcons.repeat,
                    size: 50.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ).createShader(bounds),
              child: Text(
                'Chưa có bài đăng lại',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'Các bài viết bạn đăng lại sẽ hiển thị ở đây',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVideoThumbnail(String videoUrl) {
    if (videoUrl.contains('cloudinary.com') && videoUrl.contains('/video/upload/')) {
      try {
        final uri = Uri.parse(videoUrl);
        final pathSegments = uri.pathSegments;
        final uploadIndex = pathSegments.indexOf('upload');

        if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
          final afterUpload = pathSegments.sublist(uploadIndex + 1);
          final baseUrl = '${uri.scheme}://${uri.host}';
          final uploadPath = pathSegments.sublist(0, uploadIndex + 1).join('/');
          final publicIdWithVersion = afterUpload.join('/').replaceAll('.mp4', '');
          final thumbnailUrl = '$baseUrl/$uploadPath/so_0,w_400,h_711,c_fill,q_auto/$publicIdWithVersion.jpg';
          return thumbnailUrl;
        }
      } catch (e) {
        print('❌ Error creating thumbnail: $e');
      }
    }
    return videoUrl;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _openReelViewer(ReelModel reel) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) {
          return OpenReel(reelModel: reel, userModel: widget.userModel);
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openPostDetail(ArticleModel article) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) {
          return OpenImage(articleModel: article, userModel: widget.userModel);
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}