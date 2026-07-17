import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/colors.dart';
import '../providers/user_provider.dart';
import 'home/home_screen.dart';
import 'home/search_screen.dart';
import 'library/library_screen.dart';
import 'settings/settings_screen.dart';
import 'local_files/local_files_screen.dart';
import '../widgets/now_playing_bar.dart';
import 'admin/admin_dashboard_screen.dart';

/// Responsive main screen with Spotify-style navigation
/// - Desktop/Tablet (>600px): Sidebar navigation
/// - Mobile (<600px): Bottom navigation bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final userProvider = Provider.of<UserProvider>(context);

    // List of screens available in the app
    final List<Widget> screens = [
      const HomeScreen(),
      const SearchScreen(),
      const LibraryScreen(),
      if (userProvider.isAdmin) const AdminDashboardScreen(),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          Expanded(
            child: isMobile
                ? screens[_selectedIndex >= screens.length ? 0 : _selectedIndex]
                : _buildDesktopLayout(isDark, isTablet, screens),
          ),
          const NowPlayingBar(),
        ],
      ),
      bottomNavigationBar:
          isMobile ? _buildBottomNav(isDark, userProvider.isAdmin) : null,
    );
  }

  // ========== MOBILE LAYOUT ==========
  // Removed _buildMobileLayout as it's now handled inline

  // ========== DESKTOP/TABLET LAYOUT ==========
  Widget _buildDesktopLayout(bool isDark, bool isTablet, List<Widget> screens) {
    return Row(
      children: [
        _buildSidebar(isDark, isTablet),
        Expanded(
            child:
                screens[_selectedIndex >= screens.length ? 0 : _selectedIndex]),
      ],
    );
  }

  // ========== SIDEBAR ==========
  Widget _buildSidebar(bool isDark, bool isTablet) {
    final sidebarWidth = isTablet ? 240.0 : 280.0;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : AppColors.surfaceLight,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 24),
            child: Row(
              children: [
                Icon(
                  Icons.music_note_rounded,
                  color: AppColors.primary,
                  size: isTablet ? 28 : 32,
                ),
                if (!isTablet) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Spotify',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation
          _buildNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            index: 0,
            isDark: isDark,
            compact: isTablet,
          ),
          _buildNavItem(
            icon: Icons.search_rounded,
            label: 'Search',
            index: 1,
            isDark: isDark,
            compact: isTablet,
          ),
          _buildNavItem(
            icon: Icons.library_music_rounded,
            label: 'Your Library',
            index: 2,
            isDark: isDark,
            compact: isTablet,
          ),

          if (userProvider.isAdmin)
            _buildNavItem(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Admin Panel',
              index: 3,
              isDark: isDark,
              compact: isTablet,
            ),

          const SizedBox(height: 24),
          Divider(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            height: 1,
          ),
          const SizedBox(height: 16),

          // Actions
          _buildActionItem(
            icon: Icons.add_box_outlined,
            label: 'Create Playlist',
            isDark: isDark,
            compact: isTablet,
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.favorite,
            label: 'Liked Songs',
            isDark: isDark,
            compact: isTablet,
            iconColor: AppColors.neonPink,
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.folder_outlined,
            label: 'Local Files',
            isDark: isDark,
            compact: isTablet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocalFilesScreen(),
                ),
              );
            },
          ),

          if (!isTablet) ...[
            const SizedBox(height: 16),
            Divider(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              height: 1,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildPlaylistItem('My Playlist #1', isDark),
                  _buildPlaylistItem('Chill Vibes', isDark),
                  _buildPlaylistItem('Workout Mix', isDark),
                  _buildPlaylistItem('Road Trip', isDark),
                  _buildPlaylistItem('Focus Flow', isDark),
                ],
              ),
            ),
          ] else
            const Spacer(),

          // Profile - Use Consumer to safely access UserProvider
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (userProvider.user?.displayName?.substring(0, 1) ?? 'U')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isTablet) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          userProvider.user?.displayName ?? 'User',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ========== BOTTOM NAV (Mobile) ==========
  Widget _buildBottomNav(bool isDark, bool isAdmin) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.6),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_rounded),
                  label: 'Your Library',
                ),
                if (isAdmin)
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.admin_panel_settings_rounded),
                    label: 'Admin',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
    bool compact = false,
  }) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  size: 24,
                ),
                if (!compact) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required bool isDark,
    bool compact = false,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ??
                      (isDark ? Colors.grey[400] : Colors.grey[600]),
                  size: 24,
                ),
                if (!compact) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistItem(String name, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
