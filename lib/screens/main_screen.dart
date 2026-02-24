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

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final userProvider = Provider.of<UserProvider>(context);

    // If user is Admin, show Admin Dashboard exclusively
    if (userProvider.isAdmin) {
      return const AdminDashboardScreen();
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          Expanded(
            child: isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(isDark, isTablet),
          ),
          const NowPlayingBar(),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNav(isDark) : null,
    );
  }

  // ========== MOBILE LAYOUT ==========
  Widget _buildMobileLayout() {
    return _screens[_selectedIndex];
  }

  // ========== DESKTOP/TABLET LAYOUT ==========
  Widget _buildDesktopLayout(bool isDark, bool isTablet) {
    return Row(
      children: [
        _buildSidebar(isDark, isTablet),
        Expanded(child: _screens[_selectedIndex]),
      ],
    );
  }

  // ========== SIDEBAR ==========
  Widget _buildSidebar(bool isDark, bool isTablet) {
    final sidebarWidth = isTablet ? 240.0 : 280.0;

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
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_rounded),
              label: 'Your Library',
            ),
          ],
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
                  ? AppColors.primary.withOpacity(0.1)
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
