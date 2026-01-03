import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:socialnetwork/core/widget/TextBasic.dart';
import 'package:socialnetwork/data/models/ChatModel/ChatMessage.dart';
import 'package:socialnetwork/data/models/ChatModel/Conversation.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/server/WebSocketService.dart';
import 'package:socialnetwork/data/server/user/UserApi.dart';
import 'package:socialnetwork/features/pages/message/ChatPage.dart';

class ChatListPage extends StatefulWidget {
  final String myId;

  const ChatListPage({super.key, required this.myId});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  List<UserModel> list = [];
  Map<String, bool> userActiveStatus = {};
  bool _isLoadUser = true;
  final _socketService = WebSocketService();
  final _userApi = UserApi();
  bool _isRequesting = false;

  final List<Conversation> _conversations = [];
  final Map<String, UserModel> _userCache = {};

  bool _isLoading = true;
  StreamSubscription? _conversationUpdateSub;
  StreamSubscription? _conversationsLoadedSub;
  StreamSubscription? _someoneIsOffline;
  StreamSubscription? _someoneIsOnline;
  Timer? _pollTimer;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _listenToConversationsLoaded();
    _listenToConversationUpdates();
    _loadConversations();
    _listenSomeoneIsOffline();
    _listenSomeoneIsOnline();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getFollowing();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _conversationUpdateSub?.cancel();
    _conversationsLoadedSub?.cancel();
    _someoneIsOffline?.cancel();
    _someoneIsOnline?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _listenToConversationsLoaded() {
    _conversationsLoadedSub = _socketService.conversationsLoadedStream.listen((
        conversations,
        ) {
      if (!mounted) return;

      setState(() {
        _conversations.clear();
        _conversations.addAll(conversations);
        _isLoading = false;
      });

      print('✅ Client nhận được ${conversations.length} conversations');
    });
  }

  void _listenSomeoneIsOffline() {
    _someoneIsOffline = _socketService.someoneIsOfflineStream.listen((id) {
      final parts = id.split('?');
      if (!mounted) return;
      if (userActiveStatus.containsKey(parts[0])) {
        setState(() {
          userActiveStatus[parts[0]] = false;
        });
      }
    });
  }

  void _listenSomeoneIsOnline() {
    _someoneIsOnline = _socketService.someoneIsOnlineStream.listen((id) {
      if (!mounted) return;
      if (userActiveStatus.containsKey(id)) {
        setState(() {
          userActiveStatus[id] = true;
        });
      }
    });
  }

  void _loadConversations() {
    if (_isRequesting) return;

    _isRequesting = true;

    print('📤 Requesting conversations for ${widget.myId}');

    _socketService.sendMessage({
      'type': 'load_conversations',
      'userId': widget.myId,
    });

    Future.delayed(const Duration(seconds: 1), () {
      _isRequesting = false;
    });
  }

  void _listenToConversationUpdates() {
    _conversationUpdateSub = _socketService.conversationUpdateStream.listen((
        updatedConvo,
        ) {
      if (!mounted) return;

      setState(() {
        final index = _conversations.indexWhere((c) => c.id == updatedConvo.id);

        if (index != -1) {
          _conversations[index] = updatedConvo;
          final convo = _conversations.removeAt(index);
          _conversations.insert(0, convo);
        } else {
          _conversations.insert(0, updatedConvo);
        }
      });

      print('🔔 Conversation updated: ${updatedConvo.id}');
    });
  }

  Future<void> getFollowing() async {
    final listUser = await UserApi.getFollowing(widget.myId);

    setState(() {
      list = listUser;
      userActiveStatus = {for (var user in listUser) user.id: user.isOnline};
      _isLoadUser = false;
    });
  }

  Future<UserModel?> _getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final user = await UserApi.getUserById(userId);
      if (user != null) {
        _userCache[userId] = user;
      }
      return user;
    } catch (e) {
      print('❌ Lỗi fetch user $userId: $e');
      return null;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}p';
    } else if (diff.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  String _getMessagePreview(
      Conversation convo,
      ChatMessage? lastMessage,
      int unreadCount,
      ) {
    if (lastMessage == null) {
      return 'Chưa có tin nhắn';
    }

    final isMine = lastMessage.senderType == widget.myId;
    final prefix = isMine ? 'Bạn: ' : '';

    if (!isMine && unreadCount > 1) {
      return '$unreadCount tin nhắn chưa đọc';
    }

    switch (lastMessage.type) {
      case MessageType.text:
        return prefix + lastMessage.text;
      case MessageType.image:
        return prefix + '📷 Đã gửi 1 hình ảnh';
      case MessageType.video:
        return prefix + '🎥 Đã gửi 1 video';
      case MessageType.audio:
        return prefix + '📻 Đã gửi 1 tin nhắn thoại';
      case MessageType.location:
        return prefix + '📍 Đã gửi 1 vị trí';
      case MessageType.file:
        final parts = lastMessage.text.split('?');
        final fileName = parts.length > 1 ? parts[1] : 'File';
        return prefix + '📎 $fileName';
      default:
        return prefix + lastMessage.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStoriesSection(),
          _buildMessageHeader(),
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoading()
                : _conversations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () async {
                _loadConversations();
                await Future.delayed(const Duration(seconds: 1));
              },
              color: const Color(0xFF2196F3),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  return _buildConversationItem(
                    _conversations[index],
                    index,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SKELETON LOADING ====================

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return _buildLoadingItem();
      },
    );
  }

  // ==================== IMPROVED UI COMPONENTS ====================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tin nhắn',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22.sp,
            ),
          ),
          SizedBox(width: 8.w),
          if (_getTotalUnreadCount() > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${_getTotalUnreadCount()}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 12.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.edit_outlined, size: 22.sp, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16.w),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.search, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            'Tìm kiếm tin nhắn...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 120.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        children: [
          _buildMapStory(),
          SizedBox(width: 12.w),
          if (_isLoadUser)
            ..._buildLoadingStories()
          else
            ...list.map((user) => _buildUserStory(user)),
        ],
      ),
    );
  }

  Widget _buildMapStory() {
    return Container(
      width: 75.w,
      margin: EdgeInsets.only(right: 8.w),
      child: Column(
        children: [
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF11998E).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Image.asset(
                    'assets/images/earth.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Bản đồ',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStory(UserModel user) {
    final id = user.id;
    final bool isOnline = userActiveStatus[id]!;
    return Container(
      width: 75.w,
      margin: EdgeInsets.only(right: 8.w),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  gradient: isOnline
                      ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : LinearGradient(
                    colors: [Colors.grey[300]!, Colors.grey[400]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: isOnline
                      ? [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : [],
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CircleAvatar(
                    backgroundImage: user.avatarUrl == '0'
                        ? const AssetImage('assets/images/avtMacDinh.jpg')
                        : CachedNetworkImageProvider(user.avatarUrl)
                    as ImageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          SizedBox(
            width: 70.w,
            child: Text(
              user.fullName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLoadingStories() {
    return List.generate(
      5,
          (index) => Container(
        width: 75.w,
        margin: EdgeInsets.only(right: 8.w),
        child: Column(
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              width: 60.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trò chuyện',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pending_outlined,
                  size: 16.sp,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 6.w),
                Text(
                  'Đang chờ',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Conversation convo, int index) {
    final peerId = convo.getPeerId(widget.myId);
    final unreadCount = convo.unreadCounts[widget.myId] ?? 0;
    final isUnread = unreadCount > 0;
    final lastMessage = convo.lastMessage;

    return FutureBuilder<UserModel?>(
      future: _getUserInfo(peerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingItem();
        }

        final peerUser = snapshot.data!;
        final displayName = convo.getNickname(peerId) ?? peerUser.fullName;
        final messagePreview = _getMessagePreview(
          convo,
          lastMessage,
          unreadCount,
        );
        final timeStr = lastMessage != null
            ? _formatTime(lastMessage.dateTime)
            : '';
        final isOnline = userActiveStatus[peerUser.id] ?? false;
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: isUnread
                  ? Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                width: 2,
              )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isUnread
                      ? const Color(0xFF667EEA).withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        myId: widget.myId,
                        targetUserId: peerId,
                        targetUser: peerUser,
                        isOnline: isOnline,
                        time: peerUser.lastActive,
                      ),
                    ),
                  ).then((_) {
                    _loadConversations();
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isUnread
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFF667EEA),
                                  Color(0xFF764BA2),
                                ],
                              )
                                  : null,
                              boxShadow: isUnread
                                  ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF667EEA,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : [],
                            ),
                            padding: EdgeInsets.all(3.w),
                            child: CircleAvatar(
                              radius: 28.r,
                              backgroundImage: CachedNetworkImageProvider(
                                peerUser.avatarUrl,
                              ),
                              backgroundColor: Colors.grey[300],
                            ),
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 16.w,
                                height: 16.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.black,
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (timeStr.isNotEmpty)
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: isUnread
                                          ? const Color(0xFF667EEA)
                                          : Colors.grey[600],
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    messagePreview,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isUnread
                                          ? Colors.black87
                                          : Colors.grey[600],
                                      fontWeight: isUnread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                if (isUnread)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: unreadCount > 9 ? 8.w : 10.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF667EEA),
                                          Color(0xFF764BA2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF667EEA,
                                          ).withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 200.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Bắt đầu trò chuyện với bạn bè',
            style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  int _getTotalUnreadCount() {
    return _conversations.fold<int>(
      0,
          (sum, convo) => sum + (convo.unreadCounts[widget.myId] ?? 0),
    );
  }
}