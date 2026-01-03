import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:socialnetwork/features/pages/newPost/postpage/EditNewPost.dart';
import 'package:socialnetwork/features/pages/newPost/postpage/NewPost.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/features/pages/newPost/reelspage/EditNewReel.dart';
import 'package:socialnetwork/features/pages/newPost/reelspage/NewReel.dart';
import 'package:socialnetwork/features/pages/profile/TabBar/ReelTab/ReelsTab.dart';
import 'package:socialnetwork/features/pages/reels/ReelsPage.dart'; // Đổi tên import ReelsTab

class NewPostPage extends StatefulWidget {
  const NewPostPage({super.key});

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage>
    with SingleTickerProviderStateMixin {
  List<AssetEntity> _selectedMedia = [];
  List<File> _selectedFiles = []; // List lưu file của những ảnh đã chọn
  late TabController _tabController;
  final int _maxSelection = 10; // Số lượng ảnh tối đa
  int currentPage = 0;
  AssetEntity? _selectedVideo;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
// Thêm hàm xử lý chọn video
  void _handleVideoSelection(AssetEntity video) {
    setState(() {
      _selectedVideo = video;
    });
  }

  void _handleMediaSelection(AssetEntity asset) async {
    setState(() {
      if (_selectedMedia.contains(asset)) {
        // Nếu đã chọn thì bỏ chọn
        _selectedMedia.remove(asset);
      } else {
        // Kiểm tra số lượng tối đa
        if (_selectedMedia.length < _maxSelection) {
          _selectedMedia.add(asset);
        } else {
          // Hiển thị thông báo đã đạt giới hạn
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chỉ có thể chọn tối đa $_maxSelection ảnh'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  // Hàm chuyển đổi AssetEntity thành File
  Future<void> _convertAssetsToFiles() async {
    _selectedFiles.clear();

    for (var asset in _selectedMedia) {
      final file = await asset.file;
      if (file != null) {
        _selectedFiles.add(file);
      }
    }

    print('Đã chuyển đổi ${_selectedFiles.length} file');
    print('Đường dẫn file đầu tiên: ${_selectedFiles.isNotEmpty ? _selectedFiles.first.path : "Không có"}');
  }

  void _onTabTapped(int index) {
    _tabController.animateTo(index);
    setState(() {
      currentPage = index;
    });
  }

  void _handleNext() async {


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      ),
    );

    if(currentPage == 0){
      if (_selectedMedia.isEmpty) return;
      await _convertAssetsToFiles();
      Navigator.pop(context);
      print('Số ảnh đã chọn: ${_selectedMedia.length}');
      print('Số file đã chuyển đổi: ${_selectedFiles.length}');

      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EditNewPost(
          selectedAssets: _selectedMedia,
          selectedFiles: _selectedFiles,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);  // Bắt đầu bên phải màn hình
          const end = Offset.zero;          // Kết thúc ở vị trí hiện tại
          final tween = Tween(begin: begin, end: end);
          final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.ease);

          return SlideTransition(
            position: tween.animate(curvedAnimation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),  // thời gian chuyển cảnh
      ));
    }else if(currentPage == 1){
      if (_selectedVideo == null) return;
      final file = await _selectedVideo?.file;
      Navigator.pop(context);
      if(file != null){
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => EditNewReel(
            assetEntity: _selectedVideo!,
            file: file,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);  // Bắt đầu bên phải màn hình
            const end = Offset.zero;          // Kết thúc ở vị trí hiện tại
            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.ease);

            return SlideTransition(
              position: tween.animate(curvedAnimation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),  // thời gian chuyển cảnh
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  NewPost(
                    selectedItems: _selectedMedia,
                    onMediaSelected: _handleMediaSelection,
                    maxSelection: _maxSelection,
                  ),
                  NewReels(
                    selectedVideo: _selectedVideo,
                    onVideoSelected: _handleVideoSelection,
                  ),
                ],
              ),
            ),
            _buildBottomTabBar(),
          ],
        ),
      ),
    );
  }

  // Widget: AppBar Custom
  Widget _buildCustomAppBar() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h, bottom: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tiêu đề (Bài viết mới / Thước phim mới / Tin mới)
          ValueListenableBuilder(
            valueListenable: _tabController.animation!,
            builder: (context, animationValue, child) {
              final currentIndex = animationValue.round();
              String title;
              switch (currentIndex) {
                case 1:
                  title = 'Thước phim mới';
                  break;
                case 0:
                default:
                  title = 'Bài viết mới';
                  break;
              }
              return Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),

          // Nút Tiếp (Next)
          TextButton(
            onPressed: _selectedMedia.isNotEmpty || _selectedVideo != null ? _handleNext : null,
            child: Text(
              'Tiếp',
              style: TextStyle(
                color: _selectedMedia.isNotEmpty || _selectedVideo != null
                    ? Colors.blueAccent
                    : Colors.grey[700],
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Tab Bar ở dưới cùng
  Widget _buildBottomTabBar() {
    return Container(
      height: 40.h,
      color: Colors.black,
      child: TabBar(
        controller: _tabController,
        indicatorPadding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        indicatorWeight: 0.1,
        indicatorColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        onTap: _onTabTapped,
        tabs: [
          _buildBottomTabItem('Bài viết'),
          _buildBottomTabItem('Thước phim'),
        ],
      ),
    );
  }

  // Helper: Item Tab (Text)
  Widget _buildBottomTabItem(String label) {
    return Tab(
      child: Text(
        label,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}