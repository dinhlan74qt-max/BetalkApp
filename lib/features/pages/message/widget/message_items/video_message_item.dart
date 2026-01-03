// widgets/message_items/video_message_item.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';

class VideoMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isUploading;
  final String? localPath;
  final String? thumbnailPath;
  final VoidCallback onTap;
  final Future<String?> Function(String, String)? getThumbnail;

  const VideoMessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.isUploading,
    this.localPath,
    this.thumbnailPath,
    required this.onTap,
    this.getThumbnail,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkVideo = message.text.startsWith('http');

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 180.w,
            height: 240.h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isMe ? Colors.white : Colors.white,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail
                  if (thumbnailPath != null)
                    Image.file(
                      File(thumbnailPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder();
                      },
                    )
                  else if (isNetworkVideo && !isUploading && getThumbnail != null)
                    FutureBuilder<String?>(
                      future: getThumbnail!(message.text, message.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.cover,
                          );
                        }
                        return _buildPlaceholder();
                      },
                    )
                  else
                    _buildPlaceholder(),

                  // Play button
                  if (!isUploading)
                    Center(
                      child: Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 35.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Đang tải lên...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Icon(
          Icons.videocam_rounded,
          size: 60.sp,
          color: Colors.white54,
        ),
      ),
    );
  }
}