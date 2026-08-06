import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../core/theme/colors.dart';

class AdminAddSongTab extends StatelessWidget {
  final bool isDark;
  final String? editingSongId;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController artistController;
  final TextEditingController albumController;
  final TextEditingController genreController;
  final TextEditingController durationController;
  final TextEditingController audioUrlController;
  final TextEditingController coverUrlController;
  final Uint8List? audioBytes;
  final String? audioFileName;
  final Uint8List? coverBytes;
  final String? coverFileName;
  final double uploadProgress;
  final bool isLoadingAction;
  final VoidCallback pickAudioFile;
  final VoidCallback pickCoverFile;
  final VoidCallback saveSongToFirebase;
  final VoidCallback clearForm;
  final void Function(String msg, {bool isSuccess}) setStatus;
  final BuildContext parentContext; // For Navigator.pushNamed

  const AdminAddSongTab({
    super.key,
    required this.isDark,
    required this.editingSongId,
    required this.formKey,
    required this.titleController,
    required this.artistController,
    required this.albumController,
    required this.genreController,
    required this.durationController,
    required this.audioUrlController,
    required this.coverUrlController,
    required this.audioBytes,
    required this.audioFileName,
    required this.coverBytes,
    required this.coverFileName,
    required this.uploadProgress,
    required this.isLoadingAction,
    required this.pickAudioFile,
    required this.pickCoverFile,
    required this.saveSongToFirebase,
    required this.clearForm,
    required this.setStatus,
    required this.parentContext,
  });

  Widget _buildModernField(
      TextEditingController controller, String label, IconData icon,
      {bool isRequired = false}) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.add_circle_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editingSongId != null ? 'Edit Song' : 'Add New Song',
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

          // Form
          Form(
            key: formKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16161E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Basic Info', Icons.info_outline_rounded,
                      const Color(0xFF8B5CF6)),
                  const SizedBox(height: 16),
                  _buildModernField(titleController, 'Song Title',
                      Icons.title_rounded,
                      isRequired: true),
                  const SizedBox(height: 12),
                  _buildModernField(artistController, 'Artist Name',
                      Icons.person_outline_rounded,
                      isRequired: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(albumController, 'Album',
                            Icons.album_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernField(genreController, 'Genre',
                            Icons.category_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Media Files', Icons.library_music_outlined,
                      const Color(0xFF1DB954)),
                  const SizedBox(height: 16),

                  // Audio Upload
                  const Text('Audio File (MP3, WAV, etc.)',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: isLoadingAction ? null : pickAudioFile,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: audioBytes != null
                            ? const Color(0xFF1DB954).withValues(alpha: 0.08)
                            : isDark
                                ? const Color(0xFF1E1E28)
                                : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            audioBytes != null
                                ? Icons.check_circle_rounded
                                : Icons.audio_file_rounded,
                            color: const Color(0xFF1DB954),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              audioBytes != null
                                  ? audioFileName ?? 'Audio file selected ✓'
                                  : 'Click to select audio file from your device',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildModernField(audioUrlController,
                            'Audio URL (Firebase/Cloud)', Icons.link_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildModernField(durationController,
                            'Duration (m:ss)', Icons.timer_outlined,
                            isRequired: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cover Upload
                  const Text('Cover Art',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover preview
                      if (coverBytes != null)
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(coverBytes!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      // Cover picker
                      Expanded(
                        child: InkWell(
                          onTap: isLoadingAction ? null : pickCoverFile,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: coverBytes != null
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
                                  coverBytes != null
                                      ? Icons.check_circle_rounded
                                      : Icons.add_photo_alternate_rounded,
                                  color: const Color(0xFFEC4899),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  coverBytes != null
                                      ? coverFileName ?? 'Image selected ✓'
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
                  _buildModernField(coverUrlController, 'Cover Image URL',
                      Icons.image_outlined),
                  const SizedBox(height: 28),

                  // Upload progress bar
                  if (isLoadingAction && uploadProgress > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Uploading...',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                        Text('${(uploadProgress * 100).toStringAsFixed(0)}%',
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
                        value: uploadProgress,
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
                              isLoadingAction ? null : saveSongToFirebase,
                          icon: isLoadingAction
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(editingSongId != null
                                  ? Icons.save_rounded
                                  : Icons.cloud_upload_rounded),
                          label: Text(
                            editingSongId != null
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
                      if (editingSongId != null) ...[
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: clearForm,
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
}
