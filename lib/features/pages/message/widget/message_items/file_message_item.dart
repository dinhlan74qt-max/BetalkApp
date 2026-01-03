// widgets/message_items/file_message_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';

class FileMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isUploading;
  final VoidCallback onTap;
  final String Function(int) formatFileSize;

  const FileMessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.isUploading,
    required this.onTap,
    required this.formatFileSize,
  });

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = message.text.split('?');
    final fileExtension = parts[0];
    final fileName = parts.length > 1 ? parts[1] : 'file';
    final size = parts.length > 2 ? formatFileSize(int.parse(parts[2])) : '';

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Opacity(
        opacity: isUploading ? 0.6 : 1.0,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isMe ? Colors.grey.shade200 : Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
              bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
              bottomRight: Radius.circular(isMe ? 4.r : 20.r),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isMe ? Colors.black : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: isUploading
                    ? SizedBox(
                  width: 24.sp,
                  height: 24.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(
                  _getFileIcon(fileExtension),
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName.length > 20 ? '${fileName.substring(0, 20)}...' : fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (size.isNotEmpty)
                    Text(
                      isUploading ? 'Đang tải lên...' : size,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.sp,
                      ),
                    ),
                ],
              ),
              SizedBox(width: 8.w),
              if (!isUploading) Icon(Icons.download, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }
}