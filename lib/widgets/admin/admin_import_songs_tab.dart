import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../core/theme/colors.dart';

class AdminImportSongsTab extends StatelessWidget {
  final bool isDark;
  final TextEditingController searchImportController;
  final VoidCallback searchOnlineSongs;
  final bool isSearching;
  final List<Song> searchResults;
  final bool isLoadingAction;
  final VoidCallback importAllSearchResults;
  final void Function(String query, String label) bulkImport;
  final void Function(Song song) importSingleSong;

  const AdminImportSongsTab({
    super.key,
    required this.isDark,
    required this.searchImportController,
    required this.searchOnlineSongs,
    required this.isSearching,
    required this.searchResults,
    required this.isLoadingAction,
    required this.importAllSearchResults,
    required this.bulkImport,
    required this.importSingleSong,
  });

  @override
  Widget build(BuildContext context) {
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
                  Icons.whatshot_rounded, const Color(0xFFEF4444)),
              _buildBulkImportCard('Bollywood', 'bollywood hits',
                  Icons.movie_rounded, const Color(0xFFF97316)),
              _buildBulkImportCard('Pop Songs', 'pop songs 2024',
                  Icons.star_rounded, const Color(0xFFEC4899)),
              _buildBulkImportCard('Romantic', 'romantic songs',
                  Icons.favorite_rounded, const Color(0xFFEF4444)),
              _buildBulkImportCard('Hip Hop', 'hip hop beats',
                  Icons.headphones_rounded, const Color(0xFF8B5CF6)),
              _buildBulkImportCard('EDM', 'electronic dance',
                  Icons.graphic_eq_rounded, const Color(0xFF06B6D4)),
              _buildBulkImportCard('Chill Vibes', 'chill lofi',
                  Icons.spa_rounded, const Color(0xFF10B981)),
              _buildBulkImportCard('Workout', 'workout motivation',
                  Icons.fitness_center_rounded, const Color(0xFF3B82F6)),
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
                        controller: searchImportController,
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
                        onSubmitted: (_) => searchOnlineSongs(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isSearching ? null : searchOnlineSongs,
                      icon: isSearching
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
                if (searchResults.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${searchResults.length} results found',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500]),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            isLoadingAction ? null : importAllSearchResults,
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
                  ...searchResults
                      .map((song) => _buildImportSongTile(song)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkImportCard(String label, String query, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isLoadingAction ? null : () => bulkImport(query, label),
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

  Widget _buildImportSongTile(Song song) {
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
            onPressed: () => importSingleSong(song),
          ),
        ],
      ),
    );
  }
}
