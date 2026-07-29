import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import '../providers/player_provider.dart';
import '../providers/user_provider.dart';
import '../screens/player/player_screen.dart';
import '../core/theme/colors.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, _) {
        final currentSong = playerProvider.currentSong;

        if (currentSong == null) return const SizedBox.shrink();

        return OpenContainer(
          closedColor: Colors.transparent,
          closedElevation: 0,
          openBuilder: (context, _) => PlayerScreen(song: currentSong),
          closedBuilder: (context, openContainer) {
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: openContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Album art with animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: playerProvider.isPlaying ? 52 : 48,
                          height: playerProvider.isPlaying ? 52 : 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (playerProvider.isPlaying)
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  currentSong.coverUrl,
                                  fit: BoxFit.cover,
                                ),
                                if (playerProvider.isPlaying)
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.3),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Song info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Visualizer
                                  if (playerProvider.isPlaying)
                                    _buildVisualizer(),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentSong.artist,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Like button — wired to UserProvider
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            if (!userProvider.isAuthenticated) {
                              return const SizedBox.shrink();
                            }
                            final isLiked =
                                userProvider.isSongLiked(currentSong.id);
                            return IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  key: ValueKey(isLiked),
                                  color: isLiked ? Colors.red : Colors.grey,
                                  size: 22,
                                ),
                              ),
                              onPressed: () {
                                if (isLiked) {
                                  userProvider.unlikeSong(currentSong.id);
                                } else {
                                  userProvider.likeSong(currentSong);
                                }
                              },
                            );
                          },
                        ),

                        // Playback controls
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                playerProvider.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                key: ValueKey(playerProvider.isPlaying),
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            onPressed: playerProvider.togglePlayPause,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Next button
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            onPressed: playerProvider.next,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisualizer() {
    return Row(
      children: List.generate(4, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + index * 50),
          width: 3,
          height: 8 + (index * 2),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}