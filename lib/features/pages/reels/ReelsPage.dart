import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socialnetwork/core/widget/TextBasic.dart';
import 'package:socialnetwork/data/models/PostModel/DetailsComment.dart';
import 'package:socialnetwork/data/models/ReelModel/DetailsReelModel.dart';
import 'package:socialnetwork/data/models/userModel.dart';
import 'package:socialnetwork/data/server/reelApi/ReelApi.dart';

import 'ReelItem.dart';

class ReelsPage extends StatefulWidget {
  final UserModel userModel;

  const ReelsPage({super.key, required this.userModel});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasStarted = false;
  List<DetailsReelModel> listReel = [];

  // ✅ Cache comments cho từng reel
  final Map<String, List<DetailsComment>> _commentsCache = {};

  // ✅ Cache like, share, repost status
  final Map<String, Map<String, dynamic>> _reelStatesCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getReel();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> getReel() async {
    final result = await ReelApi.getReel(widget.userModel.id);
    if (result.isNotEmpty) {
      setState(() {
        listReel = result;
      });
      // ✅ Initialize cache cho tất cả reels
      for (var reel in listReel) {
        _commentsCache[reel.reelModel.reelId] = [];
        _reelStatesCache[reel.reelModel.reelId] = {
          'isLiked': reel.isLiked,
          'isShared': reel.isShared,
          'isSaved': reel.isRePosted,
          'likeCount': reel.reelModel.likeCount,
          'shareCount': reel.reelModel.sharesCount,
          'commentCount': reel.reelModel.commentCount,
          'repostCount': reel.reelModel.repostCount,
        };
      }
    }
  }

  // ✅ Update comment cache
  void updateCommentCache(String reelId, List<DetailsComment> comments) {
    setState(() {
      _commentsCache[reelId] = comments;
    });
  }

  // ✅ Update reel state cache
  void updateReelStateCache(String reelId, Map<String, dynamic> state) {
    setState(() {
      _reelStatesCache[reelId] = {
        ..._reelStatesCache[reelId] ?? {},
        ...state,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_hasStarted)
            GestureDetector(
              onTap: () {
                setState(() {
                  _hasStarted = true;
                });
              },
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 80.sp,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Nhấn để xem Reels',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: listReel.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final reelId = listReel[index].reelModel.reelId;
                return ReelItem(
                  key: ValueKey(reelId), // ✅ Unique key để giữ state
                  reel: listReel[index],
                  userModel: widget.userModel,
                  isActive: index == _currentPage,
                  currentPage: _currentPage,
                  itemIndex: index,
                  // ✅ Pass cached data
                  cachedComments: _commentsCache[reelId] ?? [],
                  cachedState: _reelStatesCache[reelId] ?? {},
                  // ✅ Callbacks để update cache
                  onCommentsChanged: (comments) {
                    updateCommentCache(reelId, comments);
                  },
                  onStateChanged: (state) {
                    updateReelStateCache(reelId, state);
                  },
                );
              },
            ),
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              customText(
                  text: 'Reels',
                  color: Colors.white,
                  fonSize: 16.sp,
                  fonWeight: FontWeight.bold),
              SizedBox(width: 15.w),
              customText(
                  text: 'Bạn bè',
                  color: Colors.white.withOpacity(0.6),
                  fonSize: 16.sp,
                  fonWeight: FontWeight.bold),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }
}