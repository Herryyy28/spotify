import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/playlist_provider.dart';
import '../core/theme/colors.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final Song song;

  const AddToPlaylistSheet({
    super.key,
    required this.song,
  });

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToPlaylistSheet(song: song),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final _newPlaylistController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    _newPlaylistController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _newPlaylistController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Playlist Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = _newPlaylistController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext);

                setState(() => _isCreating = true);
                final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
                final success = await playlistProvider.createPlaylist(name: name);
                if (mounted) setState(() => _isCreating = false);

                if (success && playlistProvider.playlists.isNotEmpty) {
                  final newPlaylist = playlistProvider.playlists.first;
                  await playlistProvider.addSongToPlaylist(newPlaylist.id, widget.song);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${widget.song.title}" to "$name"'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create & Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final playlists = playlistProvider.playlists;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.song.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.music_note, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add to Playlist',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        widget.song.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // New Playlist button
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
            title: const Text(
              'New Playlist',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => _showCreatePlaylistDialog(context),
          ),
          const Divider(height: 1),
          // Playlists list
          if (_isCreating || playlistProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No playlists yet. Create one above!',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final containsSong = playlist.songs.any((s) => s.id == widget.song.id);

                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty
                          ? Image.network(
                              playlist.coverUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDefaultPlaylistIcon(isDark),
                            )
                          : _buildDefaultPlaylistIcon(isDark),
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${playlist.songCount} songs'),
                    trailing: containsSong
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : const Icon(Icons.add_circle_outline, color: Colors.grey),
                    onTap: () async {
                      if (containsSong) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${widget.song.title}" is already in "${playlist.name}"'),
                          ),
                        );
                        return;
                      }

                      final success = await playlistProvider.addSongToPlaylist(playlist.id, widget.song);
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${widget.song.title}" to "${playlist.name}"'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to add song to playlist')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlaylistIcon(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      color: isDark ? Colors.grey[800] : Colors.grey[300],
      child: const Icon(Icons.playlist_play, color: Colors.grey),
    );
  }
}
