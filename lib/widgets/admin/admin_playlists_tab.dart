import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist_model.dart';
import '../../core/theme/colors.dart';
import '../../screens/playlist/playlist_detail_screen.dart';

class AdminPlaylistsTab extends StatefulWidget {
  final bool isDark;

  const AdminPlaylistsTab({super.key, required this.isDark});

  @override
  State<AdminPlaylistsTab> createState() => _AdminPlaylistsTabState();
}

class _AdminPlaylistsTabState extends State<AdminPlaylistsTab> {
  void _setStatus(BuildContext context, String msg, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? AppColors.primary : AppColors.error,
      ),
    );
  }

  void _showAdminCreatePlaylistModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final coverCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Admin Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Playlist Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: coverCtrl,
              decoration: const InputDecoration(labelText: 'Cover Image URL (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = titleCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final provider = Provider.of<PlaylistProvider>(context, listen: false);
              final success = await provider.createPlaylist(
                name: name,
                description: descCtrl.text.trim(),
                coverUrl: coverCtrl.text.trim().isNotEmpty ? coverCtrl.text.trim() : null,
              );
              if (success && mounted) {
                _setStatus(context, 'Created playlist "$name"');
              } else if (mounted) {
                _setStatus(context, 'Failed to create playlist', isSuccess: false);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showManagePlaylistSongsModal(BuildContext context, Playlist playlist) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final allSongs = musicProvider.allSongs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A28) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('Manage Songs: ${playlist.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allSongs.length,
                      itemBuilder: (context, index) {
                        final song = allSongs[index];
                        final isInPlaylist = playlist.songs.any((s) => s.id == song.id);

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(song.coverUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note)),
                          ),
                          title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(song.artist),
                          trailing: IconButton(
                            icon: Icon(
                              isInPlaylist ? Icons.remove_circle : Icons.add_circle,
                              color: isInPlaylist ? AppColors.error : AppColors.primary,
                            ),
                            onPressed: () async {
                              if (isInPlaylist) {
                                await playlistProvider.removeSongFromPlaylist(playlist.id, song.id);
                                playlist.songs.removeWhere((s) => s.id == song.id);
                                playlist.songCount = playlist.songs.length;
                              } else {
                                await playlistProvider.addSongToPlaylist(playlist.id, song);
                                playlist.songs.add(song);
                                playlist.songCount = playlist.songs.length;
                              }
                              setModalState(() {});
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistFallbackIcon(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      color: isDark ? const Color(0xFF262636) : Colors.grey[300],
      child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final musicProvider = Provider.of<MusicProvider>(context);
    final playlists = [...playlistProvider.playlists, ...musicProvider.featuredPlaylists];

    return SingleChildScrollView(
      key: const ValueKey('playlists_page'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Playlist Management',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlists.length} Total System & User Playlists',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Admin Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAdminCreatePlaylistModal(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (playlists.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF161622) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.featured_play_list_outlined, size: 50, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No Playlists Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Click "New Admin Playlist" above to create one.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: widget.isDark ? const Color(0xFF161622) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: widget.isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(playlist: playlist),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty
                                ? Image.network(
                                    playlist.coverUrl!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaylistFallbackIcon(widget.isDark),
                                  )
                                : _buildPlaylistFallbackIcon(widget.isDark),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playlist.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${playlist.songCount} Songs • ${playlist.userName.isEmpty ? "System Playlist" : "By " + playlist.userName}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.playlist_add_rounded, color: AppColors.primary),
                            tooltip: 'Manage Songs',
                            onPressed: () => _showManagePlaylistSongsModal(context, playlist),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            tooltip: 'Delete Playlist',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Playlist'),
                                  content: Text('Delete "${playlist.name}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await playlistProvider.deletePlaylist(playlist.id);
                                if (mounted) _setStatus(context, 'Deleted playlist "${playlist.name}"');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
