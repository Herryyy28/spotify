import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/colors.dart';
import '../../models/song_model.dart';

class AdminUploadScreen extends StatefulWidget {
  final Song? songToEdit;
  const AdminUploadScreen({super.key, this.songToEdit});

  @override
  _AdminUploadScreenState createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();

  String? _audioFilePath;
  String? _coverImagePath;
  String? _audioUrl;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    if (widget.songToEdit != null) {
      _titleController.text = widget.songToEdit!.title;
      _artistController.text = widget.songToEdit!.artist;
      _albumController.text = widget.songToEdit!.album;
      _selectedGenres.addAll(widget.songToEdit!.genres);
      _audioUrl = widget.songToEdit!.audioUrl;
      _coverUrl = widget.songToEdit!.coverUrl;
    }
  }

  bool _isUploading = false;
  final double _uploadProgress = 0;

  final List<String> _selectedGenres = [];
  final List<String> _availableGenres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'R&B',
    'Electronic',
    'Jazz',
    'Classical',
    'Country',
    'Reggae',
    'Blues',
    'Folk',
    'Metal'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F0F0F), const Color(0xFF1A1A1A)]
                : [const Color(0xFFF5F5F7), const Color(0xFFFFFFFF)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.songToEdit != null ? 'Edit Song' : 'Upload New Music',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Media Assets'),
                      const SizedBox(height: 16),
                      _buildMediaSelectors(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Song Details'),
                      const SizedBox(height: 16),
                      _buildDetailFields(theme),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Genres'),
                      const SizedBox(height: 16),
                      _buildGenreSelector(theme),
                      const SizedBox(height: 40),
                      if (_isUploading) _buildUploadProgress(),
                      _buildActionButtons(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMediaSelectors() {
    return Row(
      children: [
        // Audio Picker
        Expanded(
          flex: 3,
          child: _buildGlassCard(
            onTap: _pickAudioFile,
            child: Column(
              children: [
                Icon(
                  _audioFilePath != null
                      ? Icons.check_circle
                      : Icons.audiotrack,
                  size: 40,
                  color: _audioFilePath != null || _audioUrl != null
                      ? Colors.green
                      : AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  _audioFilePath != null
                      ? _audioFilePath!.split('/').last
                      : (_audioUrl != null ? 'Audio Present' : 'Select Audio'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Cover Picker
        Expanded(
          flex: 2,
          child: _buildGlassCard(
            onTap: _pickCoverImage,
            child: _coverImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_coverImagePath!),
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : (_coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _coverUrl!,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.music_note, size: 40),
                        ),
                      )
                    : const Column(
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 40, color: AppColors.secondary),
                          SizedBox(height: 12),
                          Text('Artwork', style: TextStyle(fontSize: 12)),
                        ],
                      )),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailFields(ThemeData theme) {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: 'Title',
          icon: Icons.title,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _artistController,
          label: 'Artist',
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _albumController,
          label: 'Album (Optional)',
          icon: Icons.album,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: (v) =>
            v!.isEmpty && label != 'Album (Optional)' ? 'Required' : null,
      ),
    );
  }

  Widget _buildGenreSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableGenres.map((genre) {
            final isSelected = _selectedGenres.contains(genre);
            return FilterChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selected
                      ? _selectedGenres.add(genre)
                      : _selectedGenres.remove(genre);
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.3),
              checkmarkColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _uploadProgress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text('Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isUploading ? null : _uploadSong,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    widget.songToEdit != null ? 'Update Song' : 'Publish Song',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _isUploading ? null : _seedData,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Add Demo Songs (Seed)'),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
        ),
      ],
    );
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null) {
      setState(() => _audioFilePath = result.files.single.path);
    }
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() => _coverImagePath = result.files.single.path);
    }
  }

  Future<void> _uploadSong() async {
    // If editing, audio file is optional (can keep existing)
    if (!_formKey.currentState!.validate() ||
        (_audioFilePath == null && _audioUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select an audio file and fill details')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (_audioFilePath != null) {
        _audioUrl = await _firebaseService.uploadSong(
          filePath: _audioFilePath!,
          fileName: _titleController.text,
          userId: userProvider.user!.uid,
        );
      }

      if (_coverImagePath != null) {
        _coverUrl = await _firebaseService.uploadImage(
          filePath: _coverImagePath!,
          fileName: 'cover_${_titleController.text}',
          userId: userProvider.user!.uid,
        );
      }

      if (widget.songToEdit != null) {
        // Updating existing song
        final updatedSong = widget.songToEdit!.copyWith(
          title: _titleController.text,
          artist: _artistController.text,
          album: _albumController.text,
          audioUrl: _audioUrl, // Logic above ensures this is set
          coverUrl: _coverUrl,
          genres: _selectedGenres,
        );
        await _firebaseService.updateSong(updatedSong);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Song updated successfully!')));
        Navigator.pop(context, true); // Return success
      } else {
        // Adding new song
        final song = Song(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          artist: _artistController.text,
          album: _albumController.text,
          duration: '3:45', // Default for now
          durationInSeconds: 225,
          audioUrl: _audioUrl!,
          coverUrl: _coverUrl ??
              'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80',
          genres: _selectedGenres,
          releaseDate: DateTime.now(),
          artistId: userProvider.user!.uid,
        );

        await _firebaseService.addSong(song);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Song published successfully!')));
        _clearForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _seedData() async {
    setState(() => _isUploading = true);
    try {
      final demos = [
        Song(
          id: 'demo1',
          title: 'Starlight Harmony',
          artist: 'Luna Ray',
          album: 'Cosmic Voyage',
          duration: '4:20',
          durationInSeconds: 260,
          audioUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          coverUrl:
              'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500&q=80',
          genres: ['Electronic', 'Pop'],
          releaseDate: DateTime.now(),
        ),
        Song(
          id: 'demo2',
          title: 'Neon Dreams',
          artist: 'Cyber Soul',
          album: 'Digital Era',
          duration: '3:15',
          durationInSeconds: 195,
          audioUrl:
              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          coverUrl:
              'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=500&q=80',
          genres: ['Rock', 'Hip Hop'],
          releaseDate: DateTime.now(),
        ),
      ];

      for (var song in demos) {
        await _firebaseService.addSong(song);
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo songs added successfully!')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _artistController.clear();
    _albumController.clear();
    setState(() {
      _audioFilePath = null;
      _coverImagePath = null;
      _selectedGenres.clear();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }
}
