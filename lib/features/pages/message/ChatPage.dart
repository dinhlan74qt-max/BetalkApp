import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/server/WebSocketService.dart';
import 'package:socialnetwork/features/pages/message/ChatSettingsPage.dart';
import 'package:socialnetwork/features/pages/message/Manager/chat_location_manager.dart';
import 'package:socialnetwork/features/pages/message/widget/ChatInputArea.dart';
import 'package:socialnetwork/features/pages/message/widget/VoiceRecorderWidget.dart';
import 'package:socialnetwork/features/pages/message/widget/message_items/audio_message_item.dart';
import 'package:socialnetwork/features/pages/message/widget/message_items/file_message_item.dart';
import 'package:socialnetwork/features/pages/message/widget/message_items/image_message_item.dart';
import 'package:socialnetwork/features/pages/message/widget/message_items/location_message.dart';
import 'package:socialnetwork/features/pages/message/widget/message_items/text_message_item.dart';
import 'package:socialnetwork/features/pages/message/widget/message_items/video_message_item.dart';
import 'package:socialnetwork/features/pages/message/widget/VideoPlayerWidget.dart';
import 'package:socialnetwork/features/pages/message/widget/seeFull/FullImageViewer.dart';

import 'Manager/chat_audio_manager.dart';
import 'Manager/chat_media_manager.dart';
import 'Manager/chat_message_manager.dart';

class ChatPage extends StatefulWidget {
  final String myId;
  final String targetUserId;
  final UserModel targetUser;
  final bool isOnline;
  final String time;

  const ChatPage({
    super.key,
    required this.myId,
    required this.targetUserId,
    required this.targetUser,
    required this.isOnline,
    required this.time
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _socketService = WebSocketService();

  StreamSubscription? _someoneIsOffline;
  StreamSubscription? _someoneIsOnline;

  // ✅ Managers
  late final ChatMessageManager _messageManager;
  late final ChatMediaManager _mediaManager;
  late final ChatAudioManager _audioManager;
  late final LocationManager _locationManager;
  late final UserModel _peerUser;
  bool _isRecording = false;
  late bool _isOnline;
  String lastActive = 'Đang hoạt động';
  @override
  void initState() {
    super.initState();
    _peerUser = widget.targetUser;
    _isOnline = widget.isOnline;
    _listenSomeoneIsOffline();
    _listenSomeoneIsOnline();
    // ✅ Khởi tạo managers
    _messageManager = ChatMessageManager(
      socketService: _socketService,
      myId: widget.myId,
      targetUserId: widget.targetUserId,
    );
    _mediaManager = ChatMediaManager(context);
    _audioManager = ChatAudioManager();
    _locationManager = LocationManager();

    // ✅ Khởi tạo listeners
    _messageManager.initialize(() {
      if (mounted) setState(() {});
      _scrollToBottom();
    });
    if (!_isOnline) {
      lastActive = getTime(widget.time);
    }
  }

  @override
  void dispose() {
    _messageManager.dispose();
    _audioManager.disposeAll();
    _controller.dispose();
    _scrollController.dispose();
    _someoneIsOffline?.cancel();
    _someoneIsOnline?.cancel();
    super.dispose();
  }
  String getTime(String time) {
    DateTime dateTime = DateTime.parse(time);
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays < 1) {
      return '${DateFormat('HH:mm').format(dateTime)} trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatSettingsPage(
          userName: _peerUser.userName,
          avatarUrl: _peerUser.avatarUrl,
        ),
      ),
    );
  }


  void _listenSomeoneIsOffline(){
    _someoneIsOffline = _socketService.someoneIsOfflineStream.listen((id){
      if (!mounted) return;
      final parts = id.split('?');
      if(_peerUser.id == parts[0]){
        setState(() {
          _isOnline = false;
          lastActive = getTime(parts[1]);
        });
      }
    });
  }
  void _listenSomeoneIsOnline(){
    _someoneIsOnline = _socketService.someoneIsOnlineStream.listen((id){
      if (!mounted) return;
      if(_peerUser.id == id){
        setState(() {
          _isOnline = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_messageManager.isLoadingConversation) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Đang tải...'),
          backgroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_messageManager.errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text('Lỗi'), backgroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _messageManager.errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _messageManager.requestConversation,
                child: Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: _messageManager.messages.isEmpty
                ? Center(
                    child: Text(
                      'Bắt đầu cuộc trò chuyện',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    itemCount: _messageManager.messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messageManager.messages[index];
                      final showAvatar =
                          index == 0 ||
                          _messageManager.messages[index - 1].senderType !=
                              msg.senderType;

                      return _buildMessageItem(msg, showAvatar);
                    },
                  ),
          ),

          // Input area
          _isRecording
              ? VoiceRecorderWidget(
                  onSend: (audioFile) => _handleVoiceSend(audioFile),
                  onCancel: () => setState(() => _isRecording = false),
                )
              : ChatInputArea(
                  controller: _controller,
                  onSend: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      _messageManager.sendMessage(
                        type: MessageType.text,
                        text: text,
                        onStateChanged: () {
                          if (mounted) setState(() {});
                        },
                      );
                      _controller.clear();
                      _scrollToBottom();
                    }
                  },
                  onCamera: _handleCamera,
                  onImage: _handleImage,
                  onLocation: () => _handleLocation(),
                  onVoice: _handleVoice,
                  onFile: _handleFile,
                ),
        ],
      ),
    );
  }
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 30.w,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _navigateToSettings,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundImage: CachedNetworkImageProvider(
                    _peerUser.avatarUrl,
                  ),
                ),
                if(_isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _peerUser.fullName,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  _isOnline ? "Đang hoạt động" : "Hoạt động $lastActive",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.call_outlined, size: 28.sp, color: Colors.black),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.videocam_outlined, size: 30.sp, color: Colors.black),
          onPressed: () {},
        ),
        SizedBox(width: 8.w),
      ],
    );
  }



  Widget _buildMessageItem(ChatMessage msg, bool showAvatar) {
    final isMe = msg.senderType == widget.myId;
    final timeStr = DateFormat('HH:mm').format(msg.dateTime);
    final isUploading = _mediaManager.uploadingMessages[msg.id] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            showAvatar
                ? Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: InkWell(
                      onTap: _navigateToSettings,
                      child: CircleAvatar(
                        radius: 16.r,
                        backgroundImage: CachedNetworkImageProvider(
                          _peerUser.avatarUrl,
                        ),
                      ),
                    ),
                  )
                : SizedBox(width: 40.w),

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(msg, isMe, isUploading),
                Padding(
                  padding: EdgeInsets.only(top: 4.h, left: 8.w, right: 8.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11.sp,
                        ),
                      ),
                      if (isUploading) ...[
                        SizedBox(width: 4.w),
                        SizedBox(
                          width: 12.w,
                          height: 12.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[500]!,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage msg, bool isMe, bool isUploading) {
    switch (msg.type) {
      case MessageType.text:
        return TextMessageItem(message: msg, isMe: isMe);

      case MessageType.image:
        return ImageMessageItem(
          message: msg,
          isMe: isMe,
          isUploading: isUploading,
          localPath: _mediaManager.localFilePaths[msg.id],
          onTap: () => _showFullImage(msg.text),
        );

      case MessageType.video:
        return VideoMessageItem(
          message: msg,
          isMe: isMe,
          isUploading: isUploading,
          localPath: _mediaManager.localFilePaths[msg.id],
          thumbnailPath: _mediaManager.videoThumbnails[msg.id],
          onTap: () => _playVideo(msg.text),
          getThumbnail: _mediaManager.getNetworkVideoThumbnail,
        );

      case MessageType.file:
        return
          FileMessageItem(
            message: msg,
            isMe: isMe,
            isUploading: isUploading,
            onTap: () => _downloadFile(msg.text),
            formatFileSize: _mediaManager.formatFileSize,
          );

      case MessageType.audio:
        return AudioMessageItem(
          message: msg,
          isMe: isMe,
          isUploading: isUploading,
          isPlaying: _audioManager.isPlaying(msg.id),
          duration: _audioManager.getDuration(msg.id),
          position: _audioManager.getPosition(msg.id),
          onPlayPause: () => _toggleAudioPlayback(msg.id, msg.text, isMe),
          formatDuration: _audioManager.formatDuration,
          formatFileSize: _mediaManager.formatFileSize,
        );
      case MessageType.location:
        return LocationMessageItem(
          message: msg,
          isMe: isMe,
          isUploading: isUploading,
          onTap: () => _locationManager.openLocationInMap(msg.text),
        );
    }
  }

  // ==================== MEDIA HANDLERS ====================

  Future<void> _handleLocation() async {
    final location = await _mediaManager.pickLocation();
    if (location == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessage(
      id: tempId,
      conversationId: _messageManager.conversation!.id,
      senderType: widget.myId,
      text: location,
      type: MessageType.location,
      dateTime: DateTime.now(),
      isRead: false,
    );

    // ✅ Hiển thị ngay
    _messageManager.messages.insert(0, tempMessage);
    _mediaManager.uploadingMessages[tempId] = true;
    setState(() {});
    _scrollToBottom();

    try {
      _socketService.sendMessage({
        'type': 'send_message',
        'data': {
          'conversationId': _messageManager.conversation!.id,
          'senderType': widget.myId,
          'text': location,
          'type': MessageType.location.name,
        },
      });

      // ✅ Đánh dấu đã gửi thành công
      _mediaManager.uploadingMessages[tempId] = false;
      setState(() {});

    } catch (e) {
      // ✅ Xóa nếu lỗi
      _messageManager.messages.removeWhere((m) => m.id == tempId);
      _mediaManager.uploadingMessages.remove(tempId);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi vị trí: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCamera() async {
    final file = await _mediaManager.pickCamera();
    if (file != null) {
      await _uploadAndSendMedia(file, MessageType.image);
    }
  }

  Future<void> _handleImage() async {
    final result = await _mediaManager.pickMedia();
    if (result != null) {
      await _uploadAndSendMedia(result['file'], result['type']);
    }
  }

  Future<void> _handleFile() async {
    final file = await _mediaManager.pickFile();
    if (file != null) {
      await _uploadAndSendMedia(file, MessageType.file);
    }
  }

  Future<void> _handleVoice() async {
    if (await _mediaManager.requestMicrophonePermission()) {
      setState(() => _isRecording = true);
    }
  }

  Future<void> _handleVoiceSend(File audioFile) async {
    setState(() => _isRecording = false);
    await _uploadAndSendMedia(audioFile, MessageType.audio);
  }

  // ==================== UPLOAD & SEND ====================

  Future<void> _uploadAndSendMedia(File file, MessageType type) async {
    if (_messageManager.conversation == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Tạo tin nhắn tạm
    final tempMessage = ChatMessage(
      id: tempId,
      conversationId: _messageManager.conversation!.id,
      senderType: widget.myId,
      text: type == MessageType.file || type == MessageType.audio
          ? '${file.path.split('.').last}?${file.path.split('/').last}?${file.lengthSync()}'
          : file.path,
      type: type,
      dateTime: DateTime.now(),
      isRead: false,
    );

    // ✅ INSERT VÀ HIỂN THỊ NGAY
    _messageManager.messages.insert(0, tempMessage);
    _mediaManager.uploadingMessages[tempId] = true;
    _mediaManager.localFilePaths[tempId] = file.path;

    setState(() {}); // ✅ Gọi setState SAU khi đã insert
    _scrollToBottom();

    // Generate thumbnail cho video
    if (type == MessageType.video) {
      await _mediaManager.generateVideoThumbnail(file.path, tempId);
      if (mounted) setState(() {});
    }

    try {
      // Upload
      final result = await _mediaManager.uploadMedia(file, type);

      if (result == null) {
        throw Exception('Upload thất bại');
      }

      // Xây dựng text message
      String messageText;
      if (type == MessageType.file) {
        messageText = '${result['url']}?${result['fileName']}?${result['size']}';
      } else if (type == MessageType.audio) {
        messageText = '${result['url']}?${result['size']}';
      } else {
        messageText = result['url'];
      }

      // ✅ Cập nhật tin nhắn tạm → tin nhắn có URL thật
      final index = _messageManager.messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messageManager.messages[index] = ChatMessage(
          id: tempId, // ✅ Giữ nguyên tempId để _listenToMessageSent có thể xóa
          conversationId: _messageManager.conversation!.id,
          senderType: widget.myId,
          text: messageText,
          type: type,
          dateTime: _messageManager.messages[index].dateTime,
          isRead: false,
        );
      }

      _mediaManager.uploadingMessages[tempId] = false;
      _mediaManager.localFilePaths.remove(tempId);
      setState(() {});

      // ✅ Gửi qua WebSocket với URL đã upload
      _socketService.sendMessage({
        'type': 'send_message',
        'data': {
          'conversationId': _messageManager.conversation!.id,
          'senderType': widget.myId,
          'text': messageText,
          'type': type.name,
        },
      });

    } catch (e) {
      // ✅ Xóa tin nhắn tạm nếu lỗi
      if (mounted) {
        setState(() {
          _messageManager.messages.removeWhere((m) => m.id == tempId);
          _mediaManager.uploadingMessages.remove(tempId);
          _mediaManager.localFilePaths.remove(tempId);
          _mediaManager.videoThumbnails.remove(tempId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ${type.name}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ==================== AUDIO PLAYBACK ====================

  Future<void> _toggleAudioPlayback(
    String messageId,
    String audioText,
    bool isMe,
  ) async {
    try {
      final parts = audioText.split('?');
      final audioUrl = parts[0];

      await _audioManager.togglePlayback(messageId, audioUrl, () {
        if (mounted) setState(() {});
      });
    } catch (e) {
      print('❌ Lỗi phát audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể phát audio. Vui lòng thử lại!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ==================== VIEW MEDIA ===================

  void _showFullImage(String imageUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullImageViewer(imageUrl: imageUrl),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false,
      ),
    );
  }

  void _playVideo(String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => VideoPlayerWidget(videoUrl: videoUrl),
      ),
    );
  }



  Future<void> _downloadFile(String fileUrl) async {
    try {
      // Lấy tên file từ URL
      String fileName = fileUrl.split('/').last.split('?').first;
      if (fileName.isEmpty) {
        fileName = 'downloaded_file_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Xin quyền (Android 13+)
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Cần quyền truy cập bộ nhớ để tải file');
          }
        }
      }

      // Hiện loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Đang tải xuống $fileName...')),
            ],
          ),
          duration: Duration(days: 1),
          backgroundColor: Colors.blue,
        ),
      );

      // Lưu vào thư mục app (luôn có quyền)
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/$fileName';

      // Tải file bằng Dio
      await Dio().download(
        fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      // Tắt loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Thành công - hiển thị với nút mở file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Đã tải xuống: $fileName')),
            ],
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'MỞ',
            textColor: Colors.white,
            onPressed: () async {
              await OpenFile.open(filePath);
            },
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      // Tắt loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải file: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

}
