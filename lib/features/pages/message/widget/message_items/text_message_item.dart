// widgets/message_items/text_message_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';

class TextMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const TextMessageItem({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black,
          fontSize: 15.sp,
        ),
      ),
    );
  }
}