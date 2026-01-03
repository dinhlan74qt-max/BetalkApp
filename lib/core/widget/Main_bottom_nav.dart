import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialnetwork/data/repositories/prefs/UserPrefsService.dart';
import 'package:socialnetwork/features/pages/newPost/postpage/NewPost.dart';
import 'package:socialnetwork/features/pages/profile/ProfilePage.dart';
import 'package:socialnetwork/features/pages/reels/ReelsPage.dart';
import 'package:socialnetwork/features/pages/search/SearchPage.dart';

import '../../data/models/userModel.dart';
import '../../features/pages/home/HomePage.dart';
import '../../features/pages/newPost/PostTabPage.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  String? _avtUrl;
  late AnimationController _fabController;

  // Check if current page is Reels
  bool get _isReelsPage => _selectedIndex == 3;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadUser();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserPrefsService.getUser();
    final userAvatarUrl = user?.avatarUrl;

    setState(() {
      _avtUrl = userAvatarUrl;
      _pages = [
        HomePage(userModel: user!),
        SearchPage(user: user),
        const NewPostPage(),
        ReelsPage(userModel: user),
        ProfilePage(userModel: user),
      ];
    });
  }

  void _onTab(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // Animate FAB when switching tabs
      _fabController.forward().then((_) => _fabController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isReelsPage ? Colors.black : Colors.white,
          boxShadow: [
            BoxShadow(
              color: _isReelsPage
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  iconPath: 'assets/icons/bottom/home.png',
                  index: 0,
                  label: 'Home',
                ),
                _buildNavItem(
                  iconPath: 'assets/icons/bottom/search.png',
                  index: 1,
                  label: 'Search',
                ),
                _buildAddButton(),
                _buildNavItem(
                  iconPath: 'assets/icons/bottom/clapper.png',
                  index: 3,
                  label: 'Reels',
                ),
                _buildProfileNavItem(
                  iconPath: _avtUrl ?? 'assets/icons/bottom/profileBottom.png',
                  index: 4,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required int index,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: _isReelsPage
                ? [
              const Color(0xFF667EEA).withOpacity(0.2),
              const Color(0xFF764BA2).withOpacity(0.2),
            ]
                : [
              const Color(0xFF667EEA).withOpacity(0.1),
              const Color(0xFF764BA2).withOpacity(0.1),
            ],
          )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ShaderMask(
                shaderCallback: (bounds) => isSelected
                    ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ).createShader(bounds)
                    : LinearGradient(
                  colors: _isReelsPage
                      ? [Colors.grey.shade400, Colors.grey.shade400]
                      : [Colors.grey.shade500, Colors.grey.shade500],
                ).createShader(bounds),
                child: Image.asset(
                  iconPath,
                  width: isSelected ? 24 : 22,
                  height: isSelected ? 24 : 22,
                  color: Colors.white,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: _isReelsPage
                      ? [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                      : [],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({
    required String iconPath,
    required int index,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: _isReelsPage
                ? [
              const Color(0xFF667EEA).withOpacity(0.2),
              const Color(0xFF764BA2).withOpacity(0.2),
            ]
                : [
              const Color(0xFF667EEA).withOpacity(0.1),
              const Color(0xFF764BA2).withOpacity(0.1),
            ],
          )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 28 : 26,
              height: isSelected ? 28 : 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                )
                    : null,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : _isReelsPage
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                  width: isSelected ? 2.5 : 1.5,
                ),
                image: _avtUrl != null
                    ? DecorationImage(
                  image: CachedNetworkImageProvider(iconPath),
                  fit: BoxFit.cover,
                )
                    : null,
                boxShadow: isSelected && _isReelsPage
                    ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
                    : [],
              ),
              child: _avtUrl == null
                  ? Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => isSelected
                      ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ).createShader(bounds)
                      : LinearGradient(
                    colors: _isReelsPage
                        ? [Colors.grey.shade400, Colors.grey.shade400]
                        : [Colors.grey.shade500, Colors.grey.shade500],
                  ).createShader(bounds),
                  child: Image.asset(
                    iconPath,
                    width: 16,
                    height: 16,
                    color: Colors.white,
                  ),
                ),
              )
                  : null,
            ),
            if (isSelected) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: _isReelsPage
                      ? [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                      : [],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final bool isSelected = _selectedIndex == 2;

    return GestureDetector(
      onTap: () => _onTab(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isSelected ? 48 : 44,
        height: isSelected ? 48 : 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
              const Color(0xFF667EEA),
              const Color(0xFF764BA2),
            ]
                : [
              const Color(0xFF667EEA).withOpacity(0.8),
              const Color(0xFF764BA2).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(
                  _isReelsPage
                      ? (isSelected ? 0.5 : 0.4)
                      : (isSelected ? 0.4 : 0.3)
              ),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.125).animate(
              CurvedAnimation(
                parent: _fabController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Image.asset(
              'assets/icons/bottom/add.png',
              width: 22,
              height: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}