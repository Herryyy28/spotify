import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/colors.dart';
import '../providers/user_provider.dart';
import 'home/home_screen.dart';
import 'home/search_screen.dart';
import 'library/library_screen.dart';
import 'playlist/playlist_screen.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final userProvider = Provider.of<UserProvider>(context);

    // List of screens available in the app
    final List<Widget> screens = [
      HomeScreen(scaffoldKey: _scaffoldKey),
      const SearchScreen(),
      const LibraryScreen(),
      if (userProvider.isAdmin) const AdminDashboardScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      extendBody: true, // Allows body to scroll behind bottom bars for true glass effect
      body: isMobile
          ? screens[_selectedIndex >= screens.length ? 0 : _selectedIndex]
          : _buildDesktopLayout(isDark, isTablet, screens),
      drawer: isMobile
          ? Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: _buildSidebar(isDark, false),
            )
          : null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NowPlayingBar(),
          if (isMobile) _buildBottomNav(isDark, userProvider.isAdmin),
        ],
      ),
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

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.72),
            border: Border(
              right: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ===== APP LOGO (FIXED AT TOP) =====
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 20,
                    vertical: isTablet ? 20 : 24,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.spotifyGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: isTablet ? 24 : 28,
                        ),
                      ),
                      if (!isTablet) ...[
                        const SizedBox(width: 14),
                        Text(
                          'Harmony Music',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ===== SCROLLABLE MENU CONTENT =====
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🏠 CORE NAVIGATION
                        if (!isTablet)
                          _buildSectionLabel('MENU', isDark),
                        const SizedBox(height: 4),
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

                        const SizedBox(height: 14),
                        _buildGlassDivider(isDark),
                        const SizedBox(height: 14),

                        // 🎵 QUICK ACTIONS & COLLECTIONS
                        if (!isTablet)
                          _buildSectionLabel('COLLECTIONS', isDark),
                        const SizedBox(height: 4),
                        _buildActionItem(
                          icon: Icons.add_box_rounded,
                          label: 'Create Playlist',
                          isDark: isDark,
                          compact: isTablet,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlaylistScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionItem(
                          icon: Icons.favorite_rounded,
                          label: 'Liked Songs',
                          isDark: isDark,
                          compact: isTablet,
                          iconColor: AppColors.neonPink,
                          onTap: () {
                            setState(() => _selectedIndex = 2);
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

                        const SizedBox(height: 14),
                        _buildGlassDivider(isDark),
                        const SizedBox(height: 14),

                        // 👥 SOCIAL & FEATURES
                        if (!isTablet)
                          _buildSectionLabel('SOCIAL & MORE', isDark),
                        const SizedBox(height: 4),
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
                          const SizedBox(height: 14),
                          _buildGlassDivider(isDark),
                          const SizedBox(height: 6),
                          // PLAYLISTS
                          _buildSectionLabel('YOUR PLAYLISTS', isDark),
                          const SizedBox(height: 4),
                          _buildPlaylistItem('My Playlist #1', isDark),
                          _buildPlaylistItem('Chill Vibes', isDark),
                          _buildPlaylistItem('Workout Mix', isDark),
                          _buildPlaylistItem('Road Trip', isDark),
                          _buildPlaylistItem('Focus Flow', isDark),
                        ],

                        // Admin Panel (only for admins)
                        if (userProvider.isAdmin) ...[
                          const SizedBox(height: 14),
                          _buildGlassDivider(isDark),
                          const SizedBox(height: 14),
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
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ===== PROFILE BAR (FIXED AT BOTTOM) =====
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02),
                  ),
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
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
                            ),
                            if (!isTablet) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userProvider.user?.displayName ?? 'User',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
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
                ),
                if (!ResponsiveLayout.isMobile(context))
                  const SizedBox(height: 72), // Pad for NowPlayingBar
              ],
            ),
          ),
        ),
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
    bool isHovered = false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: StatefulBuilder(
        builder: (context, setHoverState) {
          return MouseRegion(
            onEnter: (_) => setHoverState(() => isHovered = true),
            onExit: (_) => setHoverState(() => isHovered = false),
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isHovered
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04))
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: isHovered && !isSelected
                      ? Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        )
                      : Border.all(color: Colors.transparent),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: isHovered
                        ? ImageFilter.blur(sigmaX: 8, sigmaY: 8)
                        : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 16,
                        vertical: 12,
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
              ),
            ),
          );
        },
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
    bool isHovered = false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: StatefulBuilder(
        builder: (context, setHoverState) {
          return MouseRegion(
            onEnter: (_) => setHoverState(() => isHovered = true),
            onExit: (_) => setHoverState(() => isHovered = false),
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isHovered
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isHovered
                      ? Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        )
                      : Border.all(color: Colors.transparent),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: isHovered
                        ? ImageFilter.blur(sigmaX: 8, sigmaY: 8)
                        : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Padding(
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassDivider(bool isDark) {
    return Divider(
      color: isDark 
          ? Colors.white.withValues(alpha: 0.08) 
          : Colors.black.withValues(alpha: 0.06),
      height: 1,
      indent: 16,
      endIndent: 16,
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
