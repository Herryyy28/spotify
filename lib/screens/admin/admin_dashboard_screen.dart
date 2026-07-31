import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';
import '../../providers/music_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/repositories/firestore_song_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../services/firebase_service.dart'; // kept for storage uploads only
import '../../services/saavn_music_service.dart';
import '../../core/utils/logger.dart';
import '../playlist/playlist_detail_screen.dart';
import '../../widgets/admin/admin_dashboard_tab.dart';
import '../../widgets/admin/admin_playlists_tab.dart';
import '../../widgets/admin/admin_library_tab.dart';
import '../../widgets/admin/admin_import_songs_tab.dart';
import '../../widgets/admin/admin_add_song_tab.dart';

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
  // Storage uploads still go through FirebaseService (handles bytes upload)
  final FirebaseService _firebaseService = FirebaseService();
  // All song CRUD goes through the repository abstraction
  final SongRepository _songRepository = FirestoreSongRepository();
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
          _buildNavItem(4, Icons.featured_play_list_rounded, 'Playlists', isDark),
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
              _buildBottomNavItem(
                  4, Icons.featured_play_list_rounded, 'Playlists', isDark),
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
                  'All Songs',
                  'Playlists'
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
        return AdminDashboardTab(
          isDark: isDark,
          onNavigate: (index) => setState(() => _selectedNavIndex = index),
          onImportTrending: _importTrendingToFirebase,
          isLoadingAction: _isLoadingAction,
          buildSongTile: _buildSongTile,
        );
      case 1:
        return AdminAddSongTab(
          isDark: isDark,
          editingSongId: _editingSongId,
          formKey: _formKey,
          titleController: _titleController,
          artistController: _artistController,
          albumController: _albumController,
          genreController: _genreController,
          durationController: _durationController,
          audioUrlController: _audioUrlController,
          coverUrlController: _coverUrlController,
          audioBytes: _audioBytes,
          audioFileName: _audioFileName,
          coverBytes: _coverBytes,
          coverFileName: _coverFileName,
          uploadProgress: _uploadProgress,
          isLoadingAction: _isLoadingAction,
          pickAudioFile: _pickAudioFile,
          pickCoverFile: _pickCoverFile,
          saveSongToFirebase: _saveSongToFirebase,
          clearForm: _clearForm,
          setStatus: _setStatus,
          parentContext: context,
        );
      case 2:
        return AdminImportSongsTab(
          isDark: isDark,
          searchImportController: _searchImportController,
          searchOnlineSongs: _searchOnlineSongs,
          isSearching: _isSearching,
          searchResults: _searchResults,
          isLoadingAction: _isLoadingAction,
          importAllSearchResults: _importAllSearchResults,
          bulkImport: _bulkImport,
          importSingleSong: _importSingleSong,
        );
      case 3:
        return AdminLibraryTab(
          isDark: isDark,
          buildSongTile: _buildSongTile,
        );
      case 4:
        return AdminPlaylistsTab(isDark: isDark);
      default:
        return const SizedBox.shrink();
    }
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
      final musicProvider = Provider.of<HomeProvider>(context, listen: false);

      if (_editingSongId != null) {
        try {
          await _songRepository.updateSong(song).timeout(const Duration(seconds: 10));
          // Update local state only after confirmed Firebase write
          musicProvider.updateSong(song);
          _setStatus('✅ Song "${song.title}" updated successfully! Live in your app.');
        } catch (e) {
          AppLogger.error('Song update error: $e');
          _setStatus('Failed to update song: $e', isSuccess: false);
        }
      } else {
        try {
          await _songRepository.addSong(song).timeout(const Duration(seconds: 10));
          // Update local state only after confirmed Firebase write
          musicProvider.addSong(song);
          _setStatus('🎉 "${song.title}" published! Instantly live on player and home screen.');
        } catch (e) {
          AppLogger.error('Song add error: $e');
          _setStatus('Failed to publish song: $e', isSuccess: false);
        }
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

      final musicProvider = Provider.of<HomeProvider>(context, listen: false);
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

      final musicProvider = Provider.of<HomeProvider>(context, listen: false);
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
      final musicProvider = Provider.of<HomeProvider>(context, listen: false);
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
      final musicProvider = Provider.of<HomeProvider>(context, listen: false);
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
            Provider.of<HomeProvider>(context, listen: false);
        await _songRepository.deleteSong(song.id);
        musicProvider.deleteSong(song.id);
        _setStatus(
            '🗑️ "${song.title}" deleted from Firebase and all user devices.');
      } catch (e) {
        _setStatus('Error deleting: $e', isSuccess: false);
      }
    }
  }
}
