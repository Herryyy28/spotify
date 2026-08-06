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
import '../core/responsive/breakpoints.dart';
import '../core/responsive/responsive_layout.dart';
import 'podcast/podcast_browse_screen.dart';
import 'social/listen_room_screen.dart';
import 'statistics/statistics_screen.dart';
import 'auth/login_screen.dart';
import '../services/auth_service.dart';

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
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);
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
      drawer: isMobile ? Drawer(child: _buildSidebar(isDark, false)) : null,
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
          // ===== APP LOGO =====
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.spotifyGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: isTablet ? 24 : 28,
                  ),
                ),
                if (!isTablet) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Harmony Music',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ===== 🏠 CORE NAVIGATION =====
          if (!isTablet)
            _buildSectionLabel('MENU', isDark),
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

          const SizedBox(height: 8),
          Divider(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 8),

          // ===== 🎵 QUICK ACTIONS & COLLECTIONS =====
          if (!isTablet)
            _buildSectionLabel('COLLECTIONS', isDark),
          _buildActionItem(
            icon: Icons.add_box_rounded,
            label: 'Create Playlist',
            isDark: isDark,
            compact: isTablet,
            onTap: () {
              // TODO: Open create playlist dialog
            },
          ),
          _buildActionItem(
            icon: Icons.favorite_rounded,
            label: 'Liked Songs',
            isDark: isDark,
            compact: isTablet,
            iconColor: AppColors.neonPink,
            onTap: () {
              // TODO: Navigate to liked songs
            },
          ),
          _buildActionItem(
            icon: Icons.podcasts_rounded,
            label: 'Podcasts',
            isDark: isDark,
            compact: isTablet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PodcastBrowseScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 8),
          Divider(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 8),

          // ===== 👥 SOCIAL & FEATURES =====
          if (!isTablet)
            _buildSectionLabel('SOCIAL & MORE', isDark),
          _buildActionItem(
            icon: Icons.headset_mic_rounded,
            label: 'Listening Room',
            isDark: isDark,
            compact: isTablet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListenRoomScreen(),
                ),
              );
            },
          ),
          _buildActionItem(
            icon: Icons.folder_open_rounded,
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
          _buildActionItem(
            icon: Icons.download_for_offline_rounded,
            label: 'Downloads',
            isDark: isDark,
            compact: isTablet,
            onTap: () {
              // TODO: Navigate to downloads screen
            },
          ),
          _buildActionItem(
            icon: Icons.bar_chart_rounded,
            label: 'Statistics',
            isDark: isDark,
            compact: isTablet,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),

          if (!isTablet) ...[
            const SizedBox(height: 8),
            Divider(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            // ===== PLAYLISTS =====
            _buildSectionLabel('YOUR PLAYLISTS', isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
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

          // ===== ⚙️ ACCOUNT & SETTINGS =====
          Divider(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            height: 1,
          ),
          // Admin Panel (only for admins)
          if (userProvider.isAdmin)
            _buildActionItem(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Admin Panel',
              isDark: isDark,
              compact: isTablet,
              iconColor: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                );
              },
            ),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Profile avatar
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (userProvider.user?.displayName?.substring(0, 1) ?? 'U')
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (!isTablet) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProvider.user?.displayName ?? 'User',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userProvider.user?.email ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Settings button
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      tooltip: 'Settings & Privacy',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    // Logout button
                    IconButton(
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: Colors.red[400],
                      ),
                      tooltip: 'Log Out',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await AuthService().signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        }
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

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 12, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
