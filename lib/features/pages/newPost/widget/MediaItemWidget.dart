import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaItemWidget extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int selectionIndex;
  final VoidCallback onTap;

  const MediaItemWidget({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.selectionIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail ảnh / video (chỉ cho image & video)
          if (asset.type == AssetType.image || asset.type == AssetType.video)
            FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize(200, 200),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                }
                return Container(color: Colors.grey[800]);
              },
            )
          else
            // Các loại asset khác: hiển thị placeholder đơn giản
            Container(
              color: Colors.grey[800],
              child: const Center(
                child: Icon(Icons.insert_drive_file, color: Colors.white),
              ),
            ),

          // Icon video nếu là video
          if (asset.type == AssetType.video)
            Positioned(
              bottom: 4.h,
              left: 4.w,
              child: Icon(Icons.videocam, color: Colors.white, size: 16.sp),
            ),

          // Duration cho video
          if (asset.type == AssetType.video)
            Positioned(
              bottom: 4.h,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                color: Colors.black.withOpacity(0.7),
                child: Text(
                  _formatDuration(asset.duration),
                  style: TextStyle(color: Colors.white, fontSize: 10.sp),
                ),
              ),
            ),

          // Border và số thứ tự khi được chọn
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 3),
                color: Colors.black.withOpacity(0.3),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: EdgeInsets.all(4.w),
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${selectionIndex + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Vòng tròn chưa chọn
          if (!isSelected)
            Positioned(
              top: 4.h,
              right: 4.w,
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
