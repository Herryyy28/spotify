import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/song_model.dart';
import '../../providers/music_provider.dart';
import '../../providers/song_upload_provider.dart';
import '../../providers/user_provider.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _albumCtrl = TextEditingController(text: 'Single');
  final _audioUrlCtrl = TextEditingController();
  final _coverUrlCtrl = TextEditingController();

  // Genre & mode state
  String _selectedGenre = 'Pop';
  bool _isExplicit = false;
  bool _useFileUpload = true; // true = file picker, false = URL input
  int _durationSeconds = 0;
  String _durationLabel = '—';

  // Picked file bytes (web-compatible)
  Uint8List? _audioBytes;
  String? _audioFileName;
  Uint8List? _coverBytes;
  String? _coverFileName;

  // Probe player for duration detection
  final _probePlayer = AudioPlayer();

  late AnimationController _shimmerCtrl;

  static const _genres = [
    'Pop', 'Rock', 'Hip-Hop', 'R&B', 'Electronic', 'Jazz',
    'Classical', 'Country', 'Reggae', 'Metal', 'Folk', 'Soul',
    'Indie', 'Alternative', 'Latin', 'K-Pop',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _albumCtrl.dispose();
    _audioUrlCtrl.dispose();
    _coverUrlCtrl.dispose();
    _probePlayer.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ─── File Picking ─────────────────────────────────────────────────────────

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _audioBytes = file.bytes;
      _audioFileName = file.name;
      _durationLabel = 'Detecting…';
    });
    await _detectDuration(bytes: file.bytes, path: file.path);
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _coverBytes = file.bytes;
      _coverFileName = file.name;
    });
  }

  Future<void> _detectDuration({Uint8List? bytes, String? path}) async {
    try {
      if (bytes != null) {
        // Web: use bytes via stream audio source workaround — probe via URL if available
        // On mobile/desktop we can use the file path
        if (!kIsWeb && path != null) {
          await _probePlayer.setFilePath(path);
        } else {
          // On web, parse from URL field if filled
          final url = _audioUrlCtrl.text.trim();
          if (url.isNotEmpty) {
            await _probePlayer.setUrl(url);
          }
        }
      } else {
        final url = _audioUrlCtrl.text.trim();
        if (url.isNotEmpty) await _probePlayer.setUrl(url);
      }
      final dur = _probePlayer.duration;
      if (dur != null) {
        final m = dur.inMinutes;
        final s = dur.inSeconds % 60;
        setState(() {
          _durationSeconds = dur.inSeconds;
          _durationLabel = '$m:${s.toString().padLeft(2, '0')}';
        });
      } else {
        setState(() => _durationLabel = 'Unknown');
      }
    } catch (_) {
      setState(() => _durationLabel = 'Unknown');
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final uploadProvider = context.read<SongUploadProvider>();
    final homeProvider = context.read<HomeProvider>();

    if (!userProvider.isAdmin) {
      _showSnack('Admin access required.', isError: true);
      return;
    }

    // Validate: need either a file or a URL
    final hasAudio = _useFileUpload
        ? _audioBytes != null
        : _audioUrlCtrl.text.trim().isNotEmpty;
    if (!hasAudio) {
      _showSnack(
        _useFileUpload ? 'Please pick an audio file.' : 'Please enter an audio URL.',
        isError: true,
      );
      return;
    }

    final coverUrl = _useFileUpload ? '' : _coverUrlCtrl.text.trim();

    final template = Song(
      id: '', // will be assigned by provider
      title: _titleCtrl.text.trim(),
      artist: _artistCtrl.text.trim(),
      album: _albumCtrl.text.trim(),
      duration: _durationLabel == '—' || _durationLabel == 'Detecting…'
          ? '3:30'
          : _durationLabel,
      durationInSeconds: _durationSeconds > 0 ? _durationSeconds : 210,
      audioUrl: _useFileUpload ? '' : _audioUrlCtrl.text.trim(),
      coverUrl: _useFileUpload ? '' : coverUrl,
      genres: [_selectedGenre],
      releaseDate: DateTime.now(),
      isExplicit: _isExplicit,
    );

    final song = await uploadProvider.uploadSong(
      songTemplate: template,
      adminUserId: userProvider.user!.uid,
      audioBytes: _useFileUpload ? _audioBytes : null,
      audioFileName: _useFileUpload ? _audioFileName : null,
      coverBytes: _useFileUpload ? _coverBytes : null,
      coverFileName: _useFileUpload ? _coverFileName : null,
    );

    if (song != null) {
      if (mounted) {
        _showSnack('🎵 "${song.title}" uploaded successfully!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } else if (mounted) {
      _showSnack(uploadProvider.errorMessage ?? 'Upload failed.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    _buildModeToggle(isDark),
                    const SizedBox(height: 24),
                    _buildAudioSection(isDark),
                    const SizedBox(height: 20),
                    _buildCoverSection(isDark),
                    const SizedBox(height: 28),
                    _buildMetadataSection(isDark, theme),
                    const SizedBox(height: 28),
                    _buildUploadButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Library',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'Upload or link a song',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _toggleOption('Upload File', Icons.upload_file_rounded, true, isDark),
          _toggleOption('Paste URL', Icons.link_rounded, false, isDark),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, IconData icon, bool value, bool isDark) {
    final active = _useFileUpload == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _useFileUpload = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: active
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioSection(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      icon: Icons.music_note_rounded,
      color: AppColors.primary,
      title: 'Audio Track',
      child: _useFileUpload
          ? Column(
              children: [
                _PickerButton(
                  label: _audioFileName ?? 'Choose MP3 / AAC / FLAC…',
                  isSelected: _audioBytes != null,
                  icon: Icons.audio_file_rounded,
                  onTap: _pickAudioFile,
                  isDark: isDark,
                ),
                if (_audioBytes != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Duration: $_durationLabel',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ],
            )
          : Column(
              children: [
                _styledField(
                  controller: _audioUrlCtrl,
                  hint: 'https://…/song.mp3',
                  icon: Icons.link_rounded,
                  isDark: isDark,
                  onChanged: (_) async {
                    if (_audioUrlCtrl.text.trim().isNotEmpty) {
                      setState(() => _durationLabel = 'Detecting…');
                      await _detectDuration();
                    }
                  },
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Audio URL required' : null,
                ),
                if (_durationLabel != '—') ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Duration: $_durationLabel',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildCoverSection(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      icon: Icons.image_rounded,
      color: AppColors.neonPurple,
      title: 'Cover Art',
      child: _useFileUpload
          ? _PickerButton(
              label: _coverFileName ?? 'Choose image (JPG / PNG)…',
              isSelected: _coverBytes != null,
              icon: Icons.photo_library_rounded,
              onTap: _pickCoverImage,
              isDark: isDark,
            )
          : _styledField(
              controller: _coverUrlCtrl,
              hint: 'https://…/cover.jpg',
              icon: Icons.link_rounded,
              isDark: isDark,
              validator: null,
            ),
    );
  }

  Widget _buildMetadataSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'SONG DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ),
        _styledField(
          controller: _titleCtrl,
          hint: 'Song title',
          icon: Icons.title_rounded,
          isDark: isDark,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Title required' : null,
        ),
        const SizedBox(height: 14),
        _styledField(
          controller: _artistCtrl,
          hint: 'Artist name',
          icon: Icons.person_rounded,
          isDark: isDark,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Artist required' : null,
        ),
        const SizedBox(height: 14),
        _styledField(
          controller: _albumCtrl,
          hint: 'Album / Single',
          icon: Icons.album_rounded,
          isDark: isDark,
          validator: null,
        ),
        const SizedBox(height: 14),
        _buildGenreDropdown(isDark),
        const SizedBox(height: 14),
        _buildExplicitToggle(isDark),
      ],
    );
  }

  Widget _buildGenreDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGenre,
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.music_note_rounded,
              color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Genre',
        ),
        dropdownColor: isDark ? AppColors.cardDark : Colors.white,
        items: _genres
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _selectedGenre = v ?? 'Pop'),
      ),
    );
  }

  Widget _buildExplicitToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.explicit_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Explicit content',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch.adaptive(
            value: _isExplicit,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            onChanged: (v) => setState(() => _isExplicit = v),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return Consumer<SongUploadProvider>(
      builder: (context, upload, _) {
        final isUploading = upload.isUploading;

        return Column(
          children: [
            // Phase label
            if (isUploading || upload.phase == UploadPhase.done) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isUploading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  if (isUploading) const SizedBox(width: 10),
                  Text(
                    upload.phaseLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Audio progress
            if (upload.phase == UploadPhase.uploadingAudio)
              _ProgressBar(
                  label: 'Audio', progress: upload.audioProgress),
            if (upload.phase == UploadPhase.uploadingCover)
              _ProgressBar(
                  label: 'Cover', progress: upload.coverProgress),
            const SizedBox(height: 16),
            // Main CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : _submit,
                  icon: isUploading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    isUploading ? upload.phaseLabel : 'Upload to Library',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: isUploading ? 0 : 4,
                    shadowColor:
                        AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            if (upload.phase == UploadPhase.error) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        upload.errorMessage ?? 'Unknown error',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: upload.reset,
                      child: const Text('Retry',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ─── Sub-Widgets ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _PickerButton({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isSelected)
              Icon(Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double progress;

  const _ProgressBar({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
