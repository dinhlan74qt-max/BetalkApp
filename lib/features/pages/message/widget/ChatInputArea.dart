import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onCamera;
  final VoidCallback? onImage;
  final VoidCallback? onLocation;
  final VoidCallback? onVoice;
  final VoidCallback? onFile;

  const ChatInputArea({
    Key? key,
    required this.controller,
    this.onSend,
    this.onCamera,
    this.onImage,
    this.onLocation,
    this.onVoice,
    this.onFile,
  }) : super(key: key);

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> with SingleTickerProviderStateMixin {
  bool _hasText = false;
  bool _showMoreOptions = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = widget.controller.text.trim().isNotEmpty;
    });
  }

  void _toggleMoreOptions() {
    setState(() {
      _showMoreOptions = !_showMoreOptions;
      if (_showMoreOptions) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // More options panel
            if (_showMoreOptions)
              _buildMoreOptionsPanel(),

            // Main input row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Nút More (mở menu phụ)
                  _buildActionButton(
                    icon: Icons.add_circle_rounded,
                    color: const Color(0xFF5e5cee),
                    onTap: _toggleMoreOptions,
                    rotation: _rotationAnimation,
                  ),
                  SizedBox(width: 8.w),

                  // Ô nhập liệu
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 44.h,
                        maxHeight: 120.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F2F6),
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // TextField
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              maxLines: null,
                              textInputAction: TextInputAction.newline,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nhắn tin...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 15.sp,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10.h, // tăng padding dọc để chữ không sát viền
                                  horizontal: 16.w,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 8.w),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Nút gửi hoặc mic
                  _buildActionButton(
                    icon: _hasText
                        ? Icons.send_rounded
                        : Icons.mic_rounded,
                    color: const Color(0xFF5e5cee),
                    onTap: _hasText ? widget.onSend : widget.onVoice,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionsPanel() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOptionItem(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            color: const Color(0xFFFF6B6B),
            onTap: widget.onCamera,
          ),
          _buildOptionItem(
            icon: Icons.photo_library_rounded,
            label: 'Thư viện',
            color: const Color(0xFF4ECDC4),
            onTap: widget.onImage,
          ),
          _buildOptionItem(
            icon: Icons.insert_drive_file_rounded,
            label: 'File',
            color: const Color(0xFFFFA502),
            onTap: widget.onFile,
          ),
          _buildOptionItem(
            icon: Icons.location_on_rounded,
            label: 'Vị trí',
            color: const Color(0xFF5e5cee),
            onTap: widget.onLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        _toggleMoreOptions(); // Đóng menu sau khi chọn
        onTap?.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 26.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    Animation<double>? rotation,
  }) {
    Widget button = Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 22.sp,
      ),
    );

    if (rotation != null) {
      button = RotationTransition(
        turns: rotation,
        child: button,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: button,
    );
  }
}