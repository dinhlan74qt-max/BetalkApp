import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class NewReels extends StatefulWidget {
  final AssetEntity? selectedVideo;
  final Function(AssetEntity) onVideoSelected;

  const NewReels({
    super.key,
    required this.selectedVideo,
    required this.onVideoSelected,
  });

  @override
  State<NewReels> createState() => _NewReelsState();
}

class _NewReelsState extends State<NewReels> {
  List<AssetEntity> _videoList = [];
  AssetPathEntity? _currentAlbum;
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 50;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadVideos();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NewReels oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi video được chọn thay đổi, dispose controller cũ
    if (oldWidget.selectedVideo != widget.selectedVideo) {
      _disposeVideoController();
      _isVideoPlaying = false;
    }
  }

  // Dispose video controller
  void _disposeVideoController() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  // Khởi tạo video player
  Future<void> _initializeVideoPlayer(AssetEntity video) async {
    try {
      _disposeVideoController();

      final file = await video.file;
      if (file == null) return;

      _videoController = VideoPlayerController.file(File(file.path));
      await _videoController!.initialize();
      await _videoController!.play();

      setState(() {
        _isVideoPlaying = true;
      });

      // Lắng nghe khi video kết thúc
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          setState(() {
            _isVideoPlaying = false;
          });
          _videoController!.seekTo(Duration.zero);
        }
      });
    } catch (e) {
      print('Lỗi khởi tạo video player: $e');
    }
  }

  // Toggle play/pause video
  void _toggleVideoPlayback() {
    if (_videoController == null) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  // Xin quyền và load video
  Future<void> _requestPermissionAndLoadVideos() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (ps.isAuth) {
      // Chỉ lấy video (onlyAll: true để lấy tất cả video từ thiết bị)
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
      );
      if (mounted) {
        setState(() {
          _currentAlbum = albums.isNotEmpty ? albums.first : null;
        });
      }
      _loadVideos();
    } else {
      PhotoManager.openSetting();
    }
  }

  // Load video từ album hiện tại
  Future<void> _loadVideos() async {
    if (_currentAlbum == null) return;

    setState(() => _isLoading = true);

    final media = await _currentAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    // Filter chỉ lấy video (double check)
    final videos = media.where((asset) => asset.type == AssetType.video).toList();

    if (mounted) {
      setState(() {
        _videoList = videos;
        _isLoading = false;
      });
    }
  }

  // Widget hiển thị video đã chọn ở trên cùng
  Widget _buildSelectedVideoView(BuildContext context) {
    final selectedVideo = widget.selectedVideo;

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
        child: selectedVideo != null
            ? GestureDetector(
          onTap: () {
            if (_videoController != null && _videoController!.value.isInitialized) {
              _toggleVideoPlayback();
            } else {
              _initializeVideoPlayer(selectedVideo);
            }
          },
          child: Container(
            margin: EdgeInsets.all(8.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.w),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hiển thị video hoặc thumbnail
                  if (_videoController != null && _videoController!.value.isInitialized)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  else
                    FutureBuilder<Uint8List?>(
                      future: selectedVideo.thumbnailDataWithSize(
                        const ThumbnailSize(800, 800),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.blueAccent),
                          ),
                        );
                      },
                    ),

                  // Overlay controls
                  if (!_isVideoPlaying)
                    Center(
                      child: Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 50.sp,
                        ),
                      ),
                    ),

                  // Nút pause khi đang phát
                  if (_isVideoPlaying)
                    Center(
                      child: AnimatedOpacity(
                        opacity: 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.pause,
                            color: Colors.white,
                            size: 50.sp,
                          ),
                        ),
                      ),
                    ),

                  // Video progress bar
                  if (_videoController != null && _videoController!.value.isInitialized)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Colors.blueAccent,
                          bufferedColor: Colors.grey[700]!,
                          backgroundColor: Colors.grey[900]!,
                        ),
                      ),
                    ),

                  // Hiển thị thời lượng
                  Positioned(
                    bottom: 16.h,
                    right: 16.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: Text(
                        _videoController != null && _videoController!.value.isInitialized
                            ? '${_formatDuration(_videoController!.value.position.inSeconds)} / ${_formatDuration(_videoController!.value.duration.inSeconds)}'
                            : _formatDuration(selectedVideo.duration),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                color: Colors.white70,
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'Chọn video cho thước phim',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget lưới video từ thư viện
  Widget _buildVideoGrid() {
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
                  _buildActionButton(Icons.videocam, () {
                    print('Mở Camera để quay video');
                  }, isSmall: true),
                ],
              ),
            ),

            // Lưới video
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : _videoList.isEmpty
                  ? Center(
                child: Text(
                  'Không có video nào',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                  ),
                ),
              )
                  : GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2.w,
                  mainAxisSpacing: 2.w,
                  childAspectRatio: 0.7,
                ),
                itemCount: _videoList.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () => print('Mở Camera để quay video'),
                      child: Container(
                        color: Colors.grey[900],
                        child: Center(
                          child: Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 30.sp,
                          ),
                        ),
                      ),
                    );
                  }

                  final video = _videoList[index - 1];
                  final isSelected = widget.selectedVideo == video;

                  return GestureDetector(
                    onTap: () => widget.onVideoSelected(video),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail video
                        FutureBuilder<Uint8List?>(
                          future: video.thumbnailDataWithSize(
                            const ThumbnailSize(200, 200),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done &&
                                snapshot.data != null) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              color: Colors.grey[900],
                            );
                          },
                        ),

                        // Overlay khi được chọn
                        if (isSelected)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 3.w,
                              ),
                            ),
                            child: Container(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),

                        // Icon play và thời lượng
                        Positioned(
                          bottom: 4.h,
                          right: 4.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4.w),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 12.sp,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  _formatDuration(video.duration),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Checkmark khi được chọn
                        if (isSelected)
                          Positioned(
                            top: 4.h,
                            right: 4.w,
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Format thời lượng video
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Helper: Nút chức năng bo tròn
  Widget _buildActionButton(IconData icon, VoidCallback onTap,
      {bool isSmall = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmall ? 35.w : 45.w,
        height: isSmall ? 35.w : 45.w,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isSmall ? 20.sp : 24.sp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSelectedVideoView(context),
        _buildVideoGrid(),
      ],
    );
  }
}