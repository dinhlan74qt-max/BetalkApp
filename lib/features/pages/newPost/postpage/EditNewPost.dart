import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:socialnetwork/core/widget/Main_bottom_nav.dart';
import 'package:socialnetwork/data/repositories/prefs/UserPrefsService.dart';
import 'package:socialnetwork/data/server/postApi/PostApi.dart';
import '../../../../core/widget/TextBasic.dart';
import 'package:just_audio/just_audio.dart';

class EditNewPost extends StatefulWidget {
  final List<AssetEntity> selectedAssets;
  final List<File> selectedFiles;

  const EditNewPost({
    super.key,
    required this.selectedAssets,
    required this.selectedFiles,
  });

  @override
  State<EditNewPost> createState() => _EditNewPostState();
}

class _EditNewPostState extends State<EditNewPost>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _captionController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _likeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;

  // Music player state
  Map<String, dynamic>? selectedSong;
  bool isPlaying = false;

  final player = AudioPlayer();


  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    );
    _fadeController.forward();
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _likeScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
        ]).animate(
          CurvedAnimation(parent: _likeController, curve: Curves.easeInOut),
        );
    _likeOpacityAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
        ]).animate(
          CurvedAnimation(parent: _likeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _captionController.dispose();
    _fadeController.dispose();
    _likeController.dispose();
    // _audioPlayer.dispose(); // Uncomment khi dùng audio player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildInstagramCarousel(),
                  _buildCaptionSection(),
                  SizedBox(height: 8.h),
                  _buildQuickActions(context),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: Colors.black87),
        iconSize: 26.sp,
        splashRadius: 24.sp,
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Bài viết mới',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade300,
                Colors.grey.shade200,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramCarousel() {
    final double carouselHeight = MediaQuery.of(context).size.width * 1.1;
    final double itemWidth = MediaQuery.of(context).size.width * 0.75;
    final double spacing = 12.w;
    return Hero(
      tag: 'post_media',
      child: Container(
        height: carouselHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ListView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: spacing,
                vertical: 16.h,
              ),
              itemCount: widget.selectedAssets.length,
              itemBuilder: (context, index) {
                return Container(
                  width: itemWidth,
                  margin: EdgeInsets.only(right: spacing),
                  child: _buildImageCard(widget.selectedAssets[index], index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(AssetEntity asset, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize(1080, 1080),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  );
                }
                return _buildShimmerLoader();
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80.h,
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
              ),
            ),
            if (asset.type == AssetType.video)
              Positioned(
                bottom: 12.h,
                left: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Center(
      child: Container(
        width: 48.w,
        height: 48.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      ),
    );
  }

  Widget _buildCaptionSection() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF0095F6), Color(0xFF00D4FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF0095F6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.person_rounded, size: 20.sp, color: Colors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: _captionController,
              maxLines: null,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
                height: 1.5,
                letterSpacing: -0.2,
              ),
              decoration: InputDecoration(
                hintText: 'Viết chú thích...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15.sp,
                  letterSpacing: -0.2,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.location_on_rounded,
            title: 'Thêm vị trí',
            subtitle: 'Chia sẻ địa điểm của bạn',
            color: Color(0xFFE91E63),
            onTap: () {
              HapticFeedback.selectionClick();
              _showLocationPicker();
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.music_note_rounded,
            title: 'Thêm nhạc',
            subtitle: selectedSong != null ? "${selectedSong!['name']} (${selectedSong!['author']})" : 'Chọn bài hát yêu thích',
            color: Color(0xFF9C27B0),
            onTap: () {
              HapticFeedback.selectionClick();
              _showMusicPicker(context);
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.public_rounded,
            title: 'Đối tượng',
            subtitle: 'Công khai',
            color: Color(0xFF2196F3),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 22.sp,
              color: Colors.grey[400],
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              _showAudiencePicker();
            },
          ),
          _buildDivider(),
          _buildActionTile(
            icon: Icons.settings_rounded,
            title: 'Cài đặt nâng cao',
            subtitle: 'Bình luận, chia sẻ, và hơn thế',
            color: Color(0xFF607D8B),
            onTap: () {
              HapticFeedback.selectionClick();
              _showAdvancedSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 22.sp, color: color),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[500],
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22.sp,
                    color: Colors.grey[400],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 70.w),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _sharePost();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
                shadowColor: const Color(0xFF0095F6).withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Chia sẻ',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

  Future<void> _sharePost() async{
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try{
      final user = await UserPrefsService.getUser();
      if(user != null){
        final userId = user.id;
        final content = _captionController.text.trim();
        final visibility = 'Mọi người';
        final result = await PostApi.newPost(userId, content, widget.selectedFiles, selectedSong?['id'] ?? '0', visibility);
        if(result){
          Navigator.pop(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(28.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0095F6), Color(0xFF00D4FF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0095F6).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 48.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Đã chia sẻ bài viết',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Bài viết của bạn với ${widget.selectedAssets.length} ${widget.selectedAssets.length > 1 ? 'ảnh' : 'ảnh'} đã được chia sẻ thành công',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        height: 1.5,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 28.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(initialIndex:0),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: animation.drive(
                                    Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                                  ),
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 1000),
                            ),
                                (Route<dynamic> route) => false,
                          );

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Hoàn tất',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }else{
          Navigator.pop(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(28.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4B4B), Color(0xFFFF7B7B)], // đỏ cảnh báo
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4B4B).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.error_rounded,      // icon lỗi
                        color: Colors.white,
                        size: 48.sp,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Tiêu đề lỗi
                    Text(
                      'Không thể chia sẻ bài viết',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 10.h),

                    // Mô tả lỗi
                    Text(
                      'Đã xảy ra lỗi trong quá trình đăng bài. Vui lòng thử lại sau.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        height: 1.5,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 28.h),

                    // Nút quay lại
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(initialIndex:0),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: animation.drive(
                                    Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                                  ),
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 1000),
                            ),
                                (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4B4B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Thử lại',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

        }
      }
    }catch(e){
      Navigator.pop(context);
      print(e.toString());
    }
  }

  void _showLocationPicker() {
    print('Chọn vị trí');
  }

  void _showMusicPicker(BuildContext context) async {
    final listFile = await loadSongs();
    _openPopup(context, listFile);
  }

  void _showAudiencePicker() {
    print('Chọn đối tượng');
  }

  void _showAdvancedSettings() {
    print('Cài đặt nâng cao');
  }

  void _openPopup(context, List<dynamic> listFile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Stack(
              children: [
                // Main bottom sheet
                Container(
                  padding: EdgeInsets.only(top: 10.h),
                  height: 400.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            color: Color(0xFF656f76),
                            height: 3.h,
                            width: 40.w,
                          ),
                        ],
                      ),
                      SizedBox(height: 25.h),
                      customText(
                        text: 'Chọn nhạc',
                        color: Colors.black,
                        fonSize: 16.sp,
                        fonWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        color: Colors.grey.shade100,
                        height: 1,
                        width: double.infinity,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: listFile.length,
                          itemBuilder: (context, index) {
                            final data = listFile[index];
                            final name = data['name'];
                            final author = data['author'];
                            final avatar = data['avatar'];
                            final file = data['file'];
                            return _customTiTle(
                              avatar,
                              name,
                              author,
                              file,
                              onTap: () async {
                                setModalState(() {
                                  selectedSong = data;
                                  isPlaying = true;
                                });
                                setState(() {
                                  selectedSong = data;
                                });
                                HapticFeedback.mediumImpact();

                                // Tự động phát nhạc khi chọn
                                await _playMusic(file);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Music player overlay (shown when song is selected)
                if (selectedSong != null)
                  Positioned(
                    left: 0, 
                    right: 0,
                    bottom: 0,
                    child: _buildMusicPlayerOverlay(setModalState),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMusicPlayerOverlay(StateSetter setModalState) {
    return Container(
      height: 90.h,
      margin: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9C27B0),
            Color(0xFFBA68C8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF9C27B0).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Album art
              Container(
                width: 65.w,
                height: 65.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: selectedSong!['avatar'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.white24,
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.white24,
                      child: Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 30.sp,
                      ),
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
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      selectedSong!['author'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Play/Pause button
              IconButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  setModalState(() {
                    isPlaying = !isPlaying;
                  });

                  if (isPlaying) {
                    await _playMusic(selectedSong!['file']);
                  } else {
                    await _pauseMusic();
                  }
                },
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),

              // Close button
              IconButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _stopMusic();
                  setModalState(() {
                    selectedSong = null;
                    isPlaying = false;
                  });
                  setState(() {
                    selectedSong = null;
                    isPlaying = false;
                  });
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),

              IconButton(
                onPressed: () async {
                  setState(() {
                    isPlaying = false;
                    player.pause();
                  });
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_circle_right_sharp,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> loadSongs() async {
    final String response = await rootBundle.loadString(
      'assets/data/songs.json',
    );
    final List data = jsonDecode(response);
    return data;
  }


  Future<void> _playMusic(String musicUrl) async {
    try {
      await player.setUrl(musicUrl);
      print('🎵 Đang phát: $musicUrl');
      setState(() {
        isPlaying = true;
        player.play();
      });

    } catch (e) {
      print('❌ Lỗi khi phát nhạc: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể phát nhạc. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Tạm dừng nhạc
  Future<void> _pauseMusic() async {
    try {
      print('⏸️ Tạm dừng nhạc');
      // await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
        player.pause();
      });
    } catch (e) {
      print('❌ Lỗi khi tạm dừng: $e');
    }
  }

  /// Dừng nhạc hoàn toàn
  Future<void> _stopMusic() async {
    try {
      print('⏹️ Dừng nhạc');
      // await _audioPlayer.stop();
      setState(() {
        isPlaying = false;
        player.stop();
      });
    } catch (e) {
      print('❌ Lỗi khi dừng nhạc: $e');
    }
  }

  Widget _customTiTle(
      String avatar,
      String name,
      String author,
      String file, {
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: CachedNetworkImage(
            imageUrl: avatar,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.music_note, color: Colors.grey[400]),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.music_note, color: Colors.grey[400]),
            ),
          ),
        ),
      ),
      title: customText(
        text: name,
        color: Colors.black,
        fonSize: 14.sp,
        fonWeight: FontWeight.w600,
      ),
      subtitle: customText(
        text: author,
        color: Colors.grey.shade400,
        fonSize: 13.sp,
        fonWeight: FontWeight.normal,
      ),
      trailing: IconButton(
        onPressed: () {},
        icon: Icon(
          Icons.bookmark_outline_outlined,
          color: Colors.grey,
          size: 25.sp,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
    );
  }
}