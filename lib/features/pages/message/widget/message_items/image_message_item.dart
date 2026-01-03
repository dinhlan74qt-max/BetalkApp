// widgets/message_items/image_message_item.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';

class ImageMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isUploading;
  final String? localPath;
  final VoidCallback onTap;

  const ImageMessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.isUploading,
    this.localPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: 250.w,
              maxHeight: 300.h,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isMe ? Colors.white : Colors.white,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: localPath != null && isUploading
                  ? Image.file(
                File(localPath!),
                fit: BoxFit.cover,
              )
                  : CachedNetworkImage(
                imageUrl: message.text,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, size: 50.sp),
                ),
              ),
            ),
          ),
          if (isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}