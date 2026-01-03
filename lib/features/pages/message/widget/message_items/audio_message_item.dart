// widgets/message_items/audio_message_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';

class AudioMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isUploading;
  final bool isPlaying;
  final Duration? duration;
  final Duration position;
  final VoidCallback onPlayPause;
  final String Function(Duration) formatDuration;
  final String Function(int) formatFileSize;

  const AudioMessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.isUploading,
    required this.isPlaying,
    this.duration,
    required this.position,
    required this.onPlayPause,
    required this.formatDuration,
    required this.formatFileSize,
  });

  @override
  Widget build(BuildContext context) {
    String fileSize = '';
    final parts = message.text.split('?');
    if (parts.length > 1) {
      try {
        fileSize = formatFileSize(int.parse(parts[1]));
      } catch (e) {
        print('⚠️ Không thể parse size: $e');
      }
    }

    int waveCount = 15;
    if (duration != null) {
      waveCount = (duration!.inSeconds / 2).clamp(15, 30).toInt();
    }

    return Container(
      constraints: BoxConstraints(
        minWidth: 150.w,
        maxWidth: 200.w,
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
          colors: [Color(0xFF9D50FF), Color(0xFF5856EC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        )
            : null,
        color: isMe ? null : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
          bottomRight: Radius.circular(isMe ? 4.r : 20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: (isMe ? Color(0xFF9D50FF) : Colors.grey).withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: isUploading ? null : onPlayPause,
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: isMe ? Colors.white : Color(0xFF9D50FF),
                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: isUploading
                  ? Padding(
                padding: EdgeInsets.all(8.w),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMe ? Color(0xFF9D50FF) : Colors.white,
                  ),
                ),
              )
                  : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 24.sp,
                color: isMe ? Color(0xFF9D50FF) : Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Waveform và thời gian
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wave animation
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    waveCount,
                        (index) {
                      final progress = duration != null && duration!.inMilliseconds > 0
                          ? position.inMilliseconds / duration!.inMilliseconds
                          : 0.0;
                      final isPassed = (index / waveCount) <= progress;

                      final heights = [12.h, 18.h, 24.h, 16.h, 20.h];
                      final barHeight = heights[index % heights.length];

                      return Container(
                        width: 2.5.w,
                        height: barHeight,
                        margin: EdgeInsets.only(right: 2.5.w),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? (isMe ? Colors.white : Color(0xFF9D50FF))
                              : (isMe
                              ? Colors.white.withOpacity(0.35)
                              : Color(0xFF9D50FF).withOpacity(0.35)),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 6.h),

                // Thời gian hoặc size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUploading
                          ? 'Đang tải lên...'
                          : formatDuration(isPlaying ? position : (duration ?? Duration.zero)),
                      style: TextStyle(
                        color: isMe ? Colors.white.withOpacity(0.9) : Colors.grey[700],
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (fileSize.isNotEmpty && !isPlaying && !isUploading)
                      Text(
                        fileSize,
                        style: TextStyle(
                          color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
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
}