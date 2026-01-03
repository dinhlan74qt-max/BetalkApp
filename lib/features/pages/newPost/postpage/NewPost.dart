import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import '../widget/MediaItemWidget.dart';

class NewPost extends StatefulWidget {
  final List<AssetEntity> selectedItems;
  final Function(AssetEntity) onMediaSelected;
  final int maxSelection;

  const NewPost({
    super.key,
    required this.selectedItems,
    required this.onMediaSelected,
    this.maxSelection = 10,
  });

  @override
  State<NewPost> createState() => _NewPostState();
}

class _NewPostState extends State<NewPost> {
  List<AssetEntity> _mediaList = [];
  AssetPathEntity? _currentAlbum;
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 50;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadMedia();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore &&
          !_isLoading) {
        _loadMoreMedia();
      }
    });
  }

  // Xin quyền và load ảnh
  Future<void> _requestPermissionAndLoadMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (ps.isAuth) {
      // Lấy album "All" để chứa toàn bộ ảnh/video, sắp xếp mới nhất trước
      final filter = FilterOptionGroup(
        orders: [
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false, // false = mới nhất trước
          ),
        ],
      );

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
        filterOption: filter,
      );
      if (mounted) {
        setState(() {
          _currentAlbum = albums.isNotEmpty ? albums.first : null;
        });
      }
      _loadMedia();
    } else {
      PhotoManager.openSetting();
    }
  }

  // Load ảnh từ album hiện tại
  Future<void> _loadMedia() async {
    if (_currentAlbum == null) return;

    setState(() => _isLoading = true);
    _currentPage = 0;
    _hasMore = true;
    _mediaList.clear();
    await _loadMoreMedia();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMoreMedia() async {
    if (_currentAlbum == null || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final media = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (!mounted) return;

    // Chỉ giữ lại ảnh và video, tránh lỗi thumbnail cho loại khác
    final filtered = media
        .where((a) => a.type == AssetType.image || a.type == AssetType.video)
        .toList();

    setState(() {
      _mediaList.addAll(filtered);
      _isLoadingMore = false;
      if (filtered.length < _pageSize) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
    });
  }

  // Widget hiển thị ảnh đã chọn ở trên cùng
  Widget _buildSelectedMediaView(BuildContext context) {
    final selectedItem = widget.selectedItems.isNotEmpty
        ? widget.selectedItems.first
        : null;

    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey[900]!],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (selectedItem != null &&
                (selectedItem.type == AssetType.image ||
                    selectedItem.type == AssetType.video))
              // Hiển thị ảnh/video lớn
              FutureBuilder<Uint8List?>(
                future: selectedItem.thumbnailDataWithSize(
                  const ThumbnailSize(800, 800),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    return Container(
                      margin: EdgeInsets.all(8.w),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.w),
                        child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                      ),
                    );
                  }
                  return Container(
                    margin: EdgeInsets.all(8.w),
                    color: Colors.grey[900],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    ),
                  );
                },
              )
            else
              Center(
                child: Text(
                  'Chọn ảnh hoặc video',
                  style: TextStyle(color: Colors.white70, fontSize: 18.sp),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget lưới ảnh từ thư viện
  Widget _buildMediaGrid() {
    return Expanded(
      flex: 1,
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            // Header với tên album
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(Icons.camera_alt, () {
                    print('Mở Camera trong thư viện');
                  }, isSmall: true),
                ],
              ),
            ),

            // Lưới ảnh
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 2.w,
                        mainAxisSpacing: 2.w,
                      ),
                      itemCount: _mediaList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return GestureDetector(
                            onTap: () => print('Mở Camera để chụp'),
                            child: Container(
                              color: Colors.grey[900],
                              child: Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 30.sp,
                                ),
                              ),
                            ),
                          );
                        }

                        final asset = _mediaList[index - 1];
                        final isSelected = widget.selectedItems.contains(asset);
                        final selectionIndex = widget.selectedItems.indexOf(
                          asset,
                        );

                        return MediaItemWidget(
                          asset: asset,
                          isSelected: isSelected,
                          selectionIndex: selectionIndex,
                          onTap: () => widget.onMediaSelected(asset),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Nút chức năng bo tròn
  Widget _buildActionButton(
    IconData icon,
    VoidCallback onTap, {
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmall ? 35.w : 45.w,
        height: isSmall ? 35.w : 45.w,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: isSmall ? 20.sp : 24.sp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_buildSelectedMediaView(context), _buildMediaGrid()],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
