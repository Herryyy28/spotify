import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../providers/player_provider.dart';
import '../core/theme/colors.dart';

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
            ? AppColors.primary.withOpacity(0.12)
            : theme.cardColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPlaying
              ? AppColors.primary.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
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
            onTap: onTap ?? () => playerProvider.playSong(song),
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
                            color: Colors.black.withOpacity(0.4),
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
}
