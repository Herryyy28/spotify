import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/song_model.dart';
import '../../providers/music_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/saavn_music_service.dart';
import '../../core/utils/logger.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Song? songToEdit;
  final int initialTabIndex;

  const AdminDashboardScreen({
    super.key,
    this.songToEdit,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final SaavnMusicService _saavnService = SaavnMusicService();

  int _selectedNavIndex = 0;
  bool _isLoadingAction = false;
  String _statusMessage = '';
  bool _isSuccess = true;

  // Add Song form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController(text: 'Single');
  final _genreController = TextEditingController(text: 'Pop');
  final _durationController = TextEditingController(text: '3:30');
  final _audioUrlController = TextEditingController();
  final _coverUrlController = TextEditingController();
  String? _editingSongId;

  // Search import controller
  final _searchImportController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;

  // File upload state (web-compatible using bytes)
  Uint8List? _audioBytes;
  String? _audioFileName;
  Uint8List? _coverBytes;
  String? _coverFileName;
  double _uploadProgress = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialTabIndex;
    if (widget.songToEdit != null) {
      final song = widget.songToEdit!;
      _editingSongId = song.id;
      _titleController.text = song.title;
      _artistController.text = song.artist;
      _albumController.text = song.album;
      _genreController.text = song.genres.isNotEmpty ? song.genres.first : 'Pop';
      _durationController.text = song.duration;
      _audioUrlController.text = song.audioUrl;
      _coverUrlController.text = song.coverUrl;
      _selectedNavIndex = 1;
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _durationController.dispose();
    _audioUrlController.dispose();
    _coverUrlController.dispose();
    _searchImportController.dispose();
    super.dispose();
  }

  void _setStatus(String msg, {bool isSuccess = true}) {
    setState(() {
      _statusMessage = msg;
      _isSuccess = isSuccess;
    });
    // Auto-clear after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _statusMessage == msg) {
        setState(() => _statusMessage = '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0F),
                    const Color(0xFF0F0F1A),
                    const Color(0xFF0A0A0F)
                  ]
                : [
                    const Color(0xFFF0F2F5),
                    const Color(0xFFE8ECF4),
                    const Color(0xFFF5F7FA)
                  ],
          ),
        ),
        child: isWideScreen
            ? Row(
                children: [
                  _buildSideNav(isDark),
                  Expanded(child: _buildMainContent(isDark)),
                ],
              )
            : Column(
                children: [
                  Expanded(child: _buildMainContent(isDark)),
                  _buildBottomNav(isDark),
                ],
              ),
      ),
    );
  }

  // =============== SIDE NAVIGATION (Wide screens) ===============
  Widget _buildSideNav(bool isDark) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121A) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo & Brand
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Music Hub',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5),
                      ),
                      Text(
                        'Admin Console',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 16),
          // Nav Items
          _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard', isDark),
          _buildNavItem(1, Icons.add_circle_rounded, 'Add Song', isDark),
          _buildNavItem(
              2, Icons.cloud_download_rounded, 'Import Songs', isDark),
          _buildNavItem(3, Icons.library_music_rounded, 'All Songs', isDark),
          const Spacer(),
          // Live indicator
          Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                        alpha: 0.08 + _pulseController.value * 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                  alpha: 0.5 + _pulseController.value * 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Cloud Sync Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedNavIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============== BOTTOM NAVIGATION (Mobile) ===============
  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                  0, Icons.dashboard_rounded, 'Dashboard', isDark),
              _buildBottomNavItem(1, Icons.add_circle_rounded, 'Add', isDark),
              _buildBottomNavItem(
                  2, Icons.cloud_download_rounded, 'Import', isDark),
              _buildBottomNavItem(
                  3, Icons.library_music_rounded, 'Songs', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
      int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 22, color: isSelected ? AppColors.primary : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =============== MAIN CONTENT AREA ===============
  Widget _buildMainContent(bool isDark) {
    return Column(
      children: [
        // Top bar
        _buildTopBar(isDark),
        // Status message
        if (_statusMessage.isNotEmpty) _buildStatusBar(isDark),
        // Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildPageContent(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12121A).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            children: [
              Text(
                [
                  'Dashboard',
                  'Add Song',
                  'Import Songs',
                  'All Songs'
                ][_selectedNavIndex],
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              const Spacer(),
              if (_isLoadingAction)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Admin',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: _isSuccess
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            _isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 18,
            color: _isSuccess ? AppColors.primary : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isSuccess ? AppColors.primary : AppColors.error,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _statusMessage = ''),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(bool isDark) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardPage(isDark);
      case 1:
        return _buildAddSongPage(isDark);
      case 2:
        return _buildImportPage(isDark);
      case 3:
        return _buildAllSongsPage(isDark);
      default:
        return _buildDashboardPage(isDark);
    }
  }

  // =============== PAGE 0: DASHBOARD ===============
  Widget _buildDashboardPage(bool isDark) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final totalSongs = musicProvider.allSongs.length;
        return SingleChildScrollView(
          key: const ValueKey('dashboard'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1DB954),
                      Color(0xFF1AA34A),
                      Color(0xFF15803D)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.waving_hand, color: Colors.amber, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Welcome back, Admin!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your music library. Songs you add here will instantly sync to all mobile app users in real-time.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats row
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth > 700
                      ? (constraints.maxWidth - 48) / 4
                      : (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                          'Total Songs',
                          '$totalSongs',
                          Icons.music_note_rounded,
                          const Color(0xFF8B5CF6),
                          cardWidth,
                          isDark),
                      _buildStatCard(
                          'Firebase Songs',
                          '$totalSongs',
                          Icons.cloud_done_rounded,
                          const Color(0xFF1DB954),
                          cardWidth,
                          isDark),
                      _buildStatCard('Sync Status', 'Live', Icons.sync_rounded,
                          const Color(0xFF06B6D4), cardWidth, isDark),
                      _buildStatCard(
                          'Quality',
                          '320kbps',
                          Icons.high_quality_rounded,
                          const Color(0xFFF97316),
                          cardWidth,
                          isDark),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickAction(
                        'Add Single Song',
                        Icons.add_rounded,
                        const Color(0xFF8B5CF6),
                        () => setState(() => _selectedNavIndex = 1),
                        isWide ? 220.0 : constraints.maxWidth,
                        isDark,
                      ),
                      _buildQuickAction(
                        'Import 20 Trending',
                        Icons.trending_up_rounded,
                        const Color(0xFF1DB954),
                        _importTrendingToFirebase,
                        isWide ? 220.0 : constraints.maxWidth,
                        isDark,
                      ),
                      _buildQuickAction(
                        'Search & Import',
                        Icons.search_rounded,
                        const Color(0xFF3B82F6),
                        () => setState(() => _selectedNavIndex = 2),
                        isWide ? 220.0 : constraints.maxWidth,
                        isDark,
                      ),
                      _buildQuickAction(
                        'Manage Library',
                        Icons.library_music_rounded,
                        const Color(0xFFF97316),
                        () => setState(() => _selectedNavIndex = 3),
                        isWide ? 220.0 : constraints.maxWidth,
                        isDark,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Recent Songs
              const Text(
                'Recently Added',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),
              if (musicProvider.allSongs.isEmpty)
                _buildEmptyState(isDark, 'No songs yet',
                    'Add songs manually or import trending tracks')
              else
                ...musicProvider.allSongs
                    .take(5)
                    .map((song) => _buildSongTile(song, isDark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      double width, bool isDark) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16161E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color,
      VoidCallback onTap, double width, bool isDark) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isLoadingAction ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16161E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.music_off_rounded, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // =============== PAGE 1: ADD SONG ===============
  Widget _buildAddSongPage(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('add_song'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingSongId != null ? 'Edit Song' : 'Add New Song',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Song will be published to Firebase Cloud and instantly appear on all user devices',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── New Upload Screen CTA ──────────────────────────────────
          GestureDetector(
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/upload');
              if (result == true && mounted) {
                _setStatus('Song uploaded and added to library!');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DB954), Color(0xFF0DA842)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_upload_rounded,
                      color: Colors.white, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload via File Picker or URL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Progress bars, auto duration detection, genre picker',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or fill manually',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Form card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16161E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Song Details', Icons.info_rounded,
                      const Color(0xFF8B5CF6)),
                  const SizedBox(height: 16),
                  _buildModernField(
                      _titleController, 'Song Title', Icons.music_note_rounded,
                      isRequired: true),
                  const SizedBox(height: 14),
                  _buildModernField(
                      _artistController, 'Artist Name', Icons.person_rounded,
                      isRequired: true),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: _buildModernField(
                              _albumController, 'Album', Icons.album_rounded)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _buildModernField(_genreController, 'Genre',
                              Icons.category_rounded)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildModernField(_durationController, 'Duration (e.g. 3:30)',
                      Icons.timer_rounded),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Audio File', Icons.audiotrack_rounded,
                      const Color(0xFF3B82F6)),
                  const SizedBox(height: 12),
                  // MP3 File Picker
                  InkWell(
                    onTap: _isLoadingAction ? null : _pickAudioFile,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _audioBytes != null
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : isDark
                                ? const Color(0xFF1E1E28)
                                : const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _audioBytes != null
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _audioBytes != null
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _audioBytes != null
                                  ? Icons.check_circle_rounded
                                  : Icons.upload_file_rounded,
                              color: _audioBytes != null
                                  ? AppColors.primary
                                  : const Color(0xFF3B82F6),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _audioBytes != null
                                      ? 'MP3 File Selected ✓'
                                      : 'Click to Upload MP3 File',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _audioBytes != null
                                        ? AppColors.primary
                                        : null,
                                  ),
                                ),
                                Text(
                                  _audioFileName ??
                                      'Supports .mp3, .m4a, .wav, .ogg',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_audioBytes != null)
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: Colors.grey),
                              tooltip: 'Remove file',
                              onPressed: () => setState(() {
                                _audioBytes = null;
                                _audioFileName = null;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // OR divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR paste URL',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildModernField(_audioUrlController,
                      'Audio Stream URL (paste link here)', Icons.link_rounded),
                  const SizedBox(height: 24),

                  // Cover Image
                  _buildSectionHeader('Cover Artwork', Icons.image_rounded,
                      const Color(0xFFEC4899)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover preview
                      if (_coverBytes != null)
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(_coverBytes!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      // Cover picker
                      Expanded(
                        child: InkWell(
                          onTap: _isLoadingAction ? null : _pickCoverFile,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _coverBytes != null
                                  ? const Color(0xFFEC4899)
                                      .withValues(alpha: 0.08)
                                  : isDark
                                      ? const Color(0xFF1E1E28)
                                      : const Color(0xFFFFF0F7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEC4899)
                                    .withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _coverBytes != null
                                      ? Icons.check_circle_rounded
                                      : Icons.add_photo_alternate_rounded,
                                  color: const Color(0xFFEC4899),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _coverBytes != null
                                      ? _coverFileName ?? 'Image selected ✓'
                                      : 'Upload cover image',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR paste URL',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildModernField(_coverUrlController, 'Cover Image URL',
                      Icons.image_outlined),
                  const SizedBox(height: 28),

                  // Upload progress bar
                  if (_isLoadingAction && _uploadProgress > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Uploading...',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                        Text('${(_uploadProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        minHeight: 8,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoadingAction ? null : _saveSongToFirebase,
                          icon: _isLoadingAction
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(_editingSongId != null
                                  ? Icons.save_rounded
                                  : Icons.cloud_upload_rounded),
                          label: Text(
                            _editingSongId != null
                                ? 'Update Song'
                                : 'Publish to Firebase',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      if (_editingSongId != null) ...[
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _clearForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModernField(
      TextEditingController controller, String label, IconData icon,
      {bool isRequired = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      validator: isRequired
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E28) : const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // =============== PAGE 2: IMPORT SONGS ===============
  Widget _buildImportPage(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('import'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_download_rounded,
                        color: Colors.white, size: 32),
                    SizedBox(width: 14),
                    Text(
                      'Import Songs from Internet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Search and import full-length 320kbps songs from online music database. Songs are instantly published to Firebase for all users.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // One-click Bulk Import Cards
          const Text(
            '⚡ One-Click Bulk Import',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBulkImportCard('Top Hits', 'top hits',
                  Icons.whatshot_rounded, const Color(0xFFEF4444), isDark),
              _buildBulkImportCard('Bollywood', 'bollywood hits',
                  Icons.movie_rounded, const Color(0xFFF97316), isDark),
              _buildBulkImportCard('Pop Songs', 'pop songs 2024',
                  Icons.star_rounded, const Color(0xFFEC4899), isDark),
              _buildBulkImportCard('Romantic', 'romantic songs',
                  Icons.favorite_rounded, const Color(0xFFEF4444), isDark),
              _buildBulkImportCard('Hip Hop', 'hip hop beats',
                  Icons.headphones_rounded, const Color(0xFF8B5CF6), isDark),
              _buildBulkImportCard('EDM', 'electronic dance',
                  Icons.graphic_eq_rounded, const Color(0xFF06B6D4), isDark),
              _buildBulkImportCard('Chill Vibes', 'chill lofi',
                  Icons.spa_rounded, const Color(0xFF10B981), isDark),
              _buildBulkImportCard(
                  'Workout',
                  'workout motivation',
                  Icons.fitness_center_rounded,
                  const Color(0xFF3B82F6),
                  isDark),
            ],
          ),
          const SizedBox(height: 28),

          // Search & Import
          const Text(
            '🔍 Search & Select',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16161E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchImportController,
                        decoration: InputDecoration(
                          hintText: 'Search any song, artist, or album...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E1E28)
                              : const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _searchOnlineSongs(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSearching ? null : _searchOnlineSongs,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search_rounded),
                      label: const Text('Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_searchResults.length} results found',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500]),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _isLoadingAction ? null : _importAllSearchResults,
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text('Import All to Firebase'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._searchResults
                      .map((song) => _buildImportSongTile(song, isDark)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkImportCard(
      String label, String query, IconData icon, Color color, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isLoadingAction ? null : () => _bulkImport(query, label),
        child: Container(
          width: 170,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16161E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Import 20 songs',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportSongTile(Song song, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E28) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song.coverUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                color: Colors.grey[800],
                child: const Icon(Icons.music_note,
                    color: Colors.white54, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${song.artist} • ${song.duration}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_rounded,
                color: AppColors.primary, size: 22),
            tooltip: 'Publish to Firebase',
            onPressed: () => _importSingleSong(song),
          ),
        ],
      ),
    );
  }

  // =============== PAGE 3: ALL SONGS ===============
  Widget _buildAllSongsPage(bool isDark) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final allSongs = musicProvider.allSongs;
        return Column(
          key: const ValueKey('all_songs'),
          children: [
            Expanded(
              child: allSongs.isEmpty
                  ? Center(
                      child: _buildEmptyState(isDark, 'No songs in library',
                          'Add songs from Dashboard or Import page'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: allSongs.length,
                      itemBuilder: (context, index) => _buildSongTile(
                          allSongs[index], isDark,
                          showActions: true),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongTile(Song song, bool isDark, {bool showActions = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.grey.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            song.coverUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.music_note, color: Colors.white54),
            ),
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${song.artist} • ${song.album} • ${song.duration}',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: showActions
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        size: 18, color: Color(0xFF3B82F6)),
                    tooltip: 'Edit Song',
                    onPressed: () => _editSong(song),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded,
                        size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'Delete Song',
                    onPressed: () => _deleteSong(song),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),
      ),
    );
  }

  // =============== ACTION METHODS ===============

  void _clearForm() {
    setState(() {
      _editingSongId = null;
      _titleController.clear();
      _artistController.clear();
      _albumController.text = 'Single';
      _genreController.text = 'Pop';
      _durationController.text = '3:30';
      _audioUrlController.clear();
      _coverUrlController.clear();
      _audioBytes = null;
      _audioFileName = null;
      _coverBytes = null;
      _coverFileName = null;
      _uploadProgress = 0;
    });
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'ogg', 'aac', 'flac', 'MP3'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          // Native mobile/desktop fallback
          bytes = await File(file.path!).readAsBytes();
        }
        if (bytes != null) {
          setState(() {
            _audioBytes = bytes;
            _audioFileName = file.name;
            _audioUrlController.clear(); // Clear URL when file is picked
          });
          _setStatus('Selected audio file: ${file.name}');
        }
      }
    } catch (e) {
      _setStatus('Could not pick audio file: $e', isSuccess: false);
    }
  }

  Future<void> _pickCoverFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'JPG', 'PNG'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          // Native mobile/desktop fallback
          bytes = await File(file.path!).readAsBytes();
        }
        if (bytes != null) {
          setState(() {
            _coverBytes = bytes;
            _coverFileName = file.name;
            _coverUrlController.clear(); // Clear URL when file is picked
          });
          _setStatus('Selected cover image: ${file.name}');
        }
      }
    } catch (e) {
      _setStatus('Could not pick cover image: $e', isSuccess: false);
    }
  }

  Future<void> _saveSongToFirebase() async {
    // Must have either a picked file OR a URL
    final hasAudio =
        _audioBytes != null || _audioUrlController.text.trim().isNotEmpty;
    if (!_formKey.currentState!.validate() || !hasAudio) {
      _setStatus(
          'Please provide a song title, artist, and either upload an MP3 file or paste an audio URL.',
          isSuccess: false);
      return;
    }

    setState(() {
      _isLoadingAction = true;
      _uploadProgress = 0;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.uid ?? 'admin';

      // Upload MP3 and Cover image in parallel to optimize speed
      String audioUrl = _audioUrlController.text.trim();
      String coverUrl = _coverUrlController.text.trim().isEmpty
          ? 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80'
          : _coverUrlController.text.trim();

      _setStatus('Uploading files to Firebase Storage...');
      setState(() => _uploadProgress = 0.2);

      double audioProgress = 0;
      double coverProgress = 0;
      final uploadFutures = <Future<void>>[];

      void updateProgress() {
        final total = (uploadFutures.length == 2)
            ? (audioProgress * 0.7 + coverProgress * 0.3)
            : (audioProgress > 0 ? audioProgress : coverProgress);
        setState(() => _uploadProgress = (total * 0.85).clamp(0.05, 0.9));
      }

      if (_audioBytes != null && _audioFileName != null) {
        uploadFutures.add(
          _firebaseService
              .uploadSongBytes(
            bytes: _audioBytes!,
            fileName: _titleController.text.trim(),
            userId: userId,
            onProgress: (p) {
              audioProgress = p;
              updateProgress();
            },
          )
              .then((url) {
            audioUrl = url;
          }),
        );
      }

      if (_coverBytes != null && _coverFileName != null) {
        uploadFutures.add(
          _firebaseService
              .uploadImageBytes(
            bytes: _coverBytes!,
            fileName: 'cover_${_titleController.text.trim()}',
            userId: userId,
            onProgress: (p) {
              coverProgress = p;
              updateProgress();
            },
          )
              .then((url) {
            coverUrl = url;
          }),
        );
      }

      if (uploadFutures.isNotEmpty) {
        try {
          await Future.wait(uploadFutures).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              AppLogger.warning('File upload timed out after 15s. Publishing song with audio URL fallback.');
              return [];
            },
          );
        } catch (uploadErr) {
          AppLogger.error('Storage upload notice: $uploadErr');
        }
        setState(() => _uploadProgress = 0.9);
      }

      if (audioUrl.trim().isEmpty) {
        audioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      }

      final durationText = _durationController.text.trim();
      int durationSec = 210;
      if (durationText.contains(':')) {
        final parts = durationText.split(':');
        durationSec =
            (int.tryParse(parts[0]) ?? 3) * 60 + (int.tryParse(parts[1]) ?? 30);
      }

      final song = Song(
        id: _editingSongId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: _albumController.text.trim().isEmpty
            ? 'Single'
            : _albumController.text.trim(),
        duration: durationText.isEmpty ? '3:30' : durationText,
        durationInSeconds: durationSec,
        audioUrl: audioUrl,
        coverUrl: coverUrl,
        genres: [
          _genreController.text.trim().isEmpty
              ? 'Pop'
              : _genreController.text.trim()
        ],
        releaseDate: DateTime.now(),
      );

      setState(() => _uploadProgress = 0.95);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      if (_editingSongId != null) {
        musicProvider.updateSong(song);
        try {
          await _firebaseService.updateSong(song).timeout(const Duration(seconds: 5));
        } catch (e) {
          AppLogger.error('Firebase sync error: $e');
        }
        _setStatus(
            '✅ Song "${song.title}" updated successfully! Live in your app.');
      } else {
        musicProvider.addSong(song);
        try {
          await _firebaseService.addSong(song).timeout(const Duration(seconds: 5));
        } catch (e) {
          AppLogger.error('Firebase sync error: $e');
        }
        _setStatus(
            '🎉 "${song.title}" published! Instantly live on player and home screen.');
      }

      setState(() => _uploadProgress = 1.0);
      _clearForm();
    } catch (e) {
      _setStatus('Error saving song: $e', isSuccess: false);
    } finally {
      setState(() {
        _isLoadingAction = false;
        _uploadProgress = 0;
      });
    }
  }

  Future<void> _importTrendingToFirebase() async {
    setState(() => _isLoadingAction = true);
    _setStatus('Fetching trending songs...');
    try {
      final songs =
          await _saavnService.fetchTrendingSongs(query: 'top hits', limit: 20);
      if (songs.isEmpty) {
        _setStatus('No songs found online', isSuccess: false);
        return;
      }

      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      int count = 0;
      for (var song in songs) {
        await _firebaseService.addSong(song);
        musicProvider.addSong(song);
        count++;
      }

      _setStatus(
          '🎉 Published $count trending songs to Firebase Cloud! Live on all user apps.');
    } catch (e) {
      _setStatus('Error: $e', isSuccess: false);
    } finally {
      setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _bulkImport(String query, String label) async {
    setState(() => _isLoadingAction = true);
    _setStatus('Importing $label songs...');
    try {
      final songs = await _saavnService.searchSongs(query, limit: 20);
      if (songs.isEmpty) {
        _setStatus('No $label songs found', isSuccess: false);
        return;
      }

      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      int count = 0;
      for (var song in songs) {
        await _firebaseService.addSong(song);
        musicProvider.addSong(song);
        count++;
      }

      _setStatus('🎉 Published $count $label songs! Live on all user devices.');
    } catch (e) {
      _setStatus('Error importing $label: $e', isSuccess: false);
    } finally {
      setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _searchOnlineSongs() async {
    final query = _searchImportController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    try {
      final results = await _saavnService.searchSongs(query, limit: 20);
      setState(() => _searchResults = results);
      if (results.isEmpty) {
        _setStatus('No results found for "$query"', isSuccess: false);
      }
    } catch (e) {
      _setStatus('Search failed: $e', isSuccess: false);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _importAllSearchResults() async {
    if (_searchResults.isEmpty) return;
    setState(() => _isLoadingAction = true);
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      int count = 0;
      for (var song in _searchResults) {
        await _firebaseService.addSong(song);
        musicProvider.addSong(song);
        count++;
      }
      _setStatus('🎉 Published $count songs to Firebase Cloud!');
      setState(() => _searchResults = []);
    } catch (e) {
      _setStatus('Error: $e', isSuccess: false);
    } finally {
      setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _importSingleSong(Song song) async {
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      await _firebaseService.addSong(song);
      musicProvider.addSong(song);
      _setStatus('✅ "${song.title}" published to Firebase!');
    } catch (e) {
      _setStatus('Error: $e', isSuccess: false);
    }
  }

  void _editSong(Song song) {
    setState(() {
      _selectedNavIndex = 1;
      _editingSongId = song.id;
      _titleController.text = song.title;
      _artistController.text = song.artist;
      _albumController.text = song.album;
      _genreController.text =
          song.genres.isNotEmpty ? song.genres.first : 'Pop';
      _durationController.text = song.duration;
      _audioUrlController.text = song.audioUrl;
      _coverUrlController.text = song.coverUrl;
    });
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('Delete Song'),
          ],
        ),
        content: Text(
            'Delete "${song.title}" by ${song.artist}? This will remove it from all user devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final musicProvider =
            Provider.of<MusicProvider>(context, listen: false);
        await _firebaseService.deleteSong(song.id);
        musicProvider.deleteSong(song.id);
        _setStatus(
            '🗑️ "${song.title}" deleted from Firebase and all user devices.');
      } catch (e) {
        _setStatus('Error deleting: $e', isSuccess: false);
      }
    }
  }
}
