import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../providers/player_provider.dart';
import '../providers/user_provider.dart';
import '../core/theme/colors.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../services/firebase_service.dart';
import '../screens/player/player_screen.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final int index;

  const SongTile({
    super.key,
    required this.song,
    this.isPlaying = false,
    this.onTap,
    this.onMenuTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPlaying
            ? AppColors.primary.withValues(alpha: 0.12)
            : theme.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPlaying
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () {
              playerProvider.playSong(song);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(song: song),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Album art with Animated Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Hero(
                        tag: 'song_art_${song.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: song.coverUrl,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color:
                                  isDark ? Colors.grey[900] : Colors.grey[200],
                              child: const Center(
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))),
                            ),
                          ),
                        ),
                      ),
                      if (isPlaying)
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(Icons.equalizer,
                                color: Colors.white, size: 24),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPlaying ? AppColors.primary : null,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                song.artist,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (song.isExplicit)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(Icons.explicit,
                                    size: 14,
                                    color:
                                        isDark ? Colors.white54 : Colors.grey),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // End Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.getFormattedDuration(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          if (!userProvider.isAdmin) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(Icons.more_vert_rounded),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showAdminMenu(context, song),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          playerProvider.currentSong?.id == song.id &&
                                  playerProvider.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        color: isPlaying
                            ? AppColors.primary
                            : (isDark ? Colors.white70 : Colors.black87),
                        onPressed: onTap ??
                            () {
                              if (playerProvider.currentSong?.id == song.id) {
                                playerProvider.togglePlayPause();
                              } else {
                                playerProvider.playSong(song);
                              }
                            },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminMenu(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('Edit Song Details'),
              subtitle: const Text('Update title, artist, or cover art'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Song'),
              subtitle: const Text('Remove this song from public library'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, song);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song?'),
        content: Text(
            'Are you sure you want to delete "${song.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseService().deleteSong(song.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Song deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
