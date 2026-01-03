import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:socialnetwork/core/widget/TextBasic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/features/pages/home/story/EditStoryPage.dart';
import 'package:video_player/video_player.dart';

class AddStoryPage extends StatefulWidget {
  final UserModel userModel;
  const AddStoryPage({super.key, required this.userModel});

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  List<AssetEntity> _mediaList = [];
  AssetPathEntity? _currentAlbum;
  List<AssetPathEntity> _albums = [];
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 50;

  AssetEntity? _selectedMedia;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadMedia();
  }

  Future<void> _requestPermissionAndLoadMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (ps.isAuth) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: false,
      );
      if (mounted) {
        setState(() {
          _albums = albums;
          _currentAlbum = albums.isNotEmpty ? albums.first : null;
        });
      }
      _loadMedia();
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> _loadMedia() async {
    if (_currentAlbum == null) return;

    setState(() => _isLoading = true);

    final media = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (mounted) {
      setState(() {
        _mediaList = media;
        _isLoading = false;
        // Auto select first media
        if (_selectedMedia == null && media.isNotEmpty) {
          _selectMedia(media.first);
        }
      });
    }
  }

  Future<void> _selectMedia(AssetEntity media) async {
    // Dispose previous video controller
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _selectedMedia = media;
    });

    // Initialize video player if media is video
    if (media.type == AssetType.video) {
      final file = await media.file;
      if (file != null && mounted) {
        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _showAlbumPicker() async {
    final selected = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 10.h),
                height: 4.h,
                width: 45.w,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Chọn album',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.builder(
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: FutureBuilder<List<AssetEntity>>(
                            future: album.getAssetListRange(start: 0, end: 1),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image(
                                    image: AssetEntityImageProvider(
                                      snapshot.data!.first,
                                      isOriginal: false,
                                      thumbnailSize: ThumbnailSize.square(200),
                                    ),
                                    fit: BoxFit.cover,
                                    width: 50.w,
                                    height: 50.w,
                                  ),
                                );
                              }
                              return Container(
                                width: 50.w,
                                height: 50.w,
                                color: Colors.grey[300],
                              );
                            },
                          ),
                          title: Text(album.name),
                          subtitle: Text('${snapshot.data ?? 0}'),
                          trailing: _currentAlbum?.id == album.id
                              ? Icon(Icons.check, color: Colors.blue)
                              : null,
                          onTap: () {
                            Navigator.pop(context, album);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );

    if (selected != null && selected.id != _currentAlbum?.id) {
      setState(() {
        _currentAlbum = selected;
        _currentPage = 0;
        _mediaList.clear();
        _selectedMedia = null;
      });
      _loadMedia();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _showAlbumPicker,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentAlbum?.name ?? 'Album',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
        actions: [
          if (_selectedMedia != null)
            TextButton(
              onPressed: () {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>  EditStoryPage(selectedAsset: _selectedMedia!,userModel: widget.userModel,),
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
              },
              child: Text(
                'Tiếp',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Preview area
          Expanded(
            flex: 3,
            child: _buildPreview(),
          ),

          // Gallery grid
          Expanded(
            flex: 2,
            child: _buildGallery(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_selectedMedia == null) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: _selectedMedia!.type == AssetType.video
          ? _buildVideoPreview()
          : _buildImagePreview(),
    );
  }

  Widget _buildImagePreview() {
    return Image(
      image: AssetEntityImageProvider(
        _selectedMedia!,
        isOriginal: false,
        thumbnailSize: ThumbnailSize.square(1000),
      ),
      fit: BoxFit.contain,
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
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
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (!_videoController!.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(16.w),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48.sp,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_mediaList.isEmpty) {
      return Center(
        child: Text(
          'Không có ảnh hoặc video',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: GridView.builder(
        padding: EdgeInsets.all(2.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 2.w,
          crossAxisSpacing: 2.w,
        ),
        itemCount: _mediaList.length,
        itemBuilder: (context, index) {
          final media = _mediaList[index];
          final isSelected = _selectedMedia?.id == media.id;

          return GestureDetector(
            onTap: () => _selectMedia(media),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: AssetEntityImageProvider(
                    media,
                    isOriginal: false,
                    thumbnailSize: ThumbnailSize.square(200),
                  ),
                  fit: BoxFit.cover,
                ),

                // Video indicator
                if (media.type == AssetType.video)
                  Positioned(
                    top: 4.w,
                    right: 4.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _formatDuration(media.duration),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Selection border
                if (isSelected)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 3.w,
                      ),
                    ),
                  ),

                // Selection indicator
                if (isSelected)
                  Positioned(
                    bottom: 4.w,
                    right: 4.w,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.w,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14.sp,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}