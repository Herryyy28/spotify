import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/colors.dart';
import '../../providers/player_provider.dart';
import '../../widgets/dynamic_theme_builder.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSong = playerProvider.currentSong;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentSong == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No song playing',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: DynamicThemeBuilder(
        imageUrl: currentSong.coverUrl,
        builder: (context, colors, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.keyboard_arrow_down),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          'PLAYING FROM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.album,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Album Art
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Hero(
                  tag: 'album_art_${currentSong.id}',
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width - 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: currentSong.coverUrl.isNotEmpty
                          ? Image.network(
                              currentSong.coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.neonPurple,
                                      AppColors.neonBlue,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.neonPurple,
                                    AppColors.neonBlue,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong.title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentSong.artist,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          color: isDark ? Colors.white : Colors.black,
                          iconSize: 28,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: Colors.white,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value:
                            playerProvider.currentPosition.inSeconds.toDouble(),
                        max: playerProvider.totalDuration.inSeconds.toDouble() >
                                0
                            ? playerProvider.totalDuration.inSeconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          playerProvider
                              .seekTo(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerProvider.currentPosition),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            _formatDuration(playerProvider.totalDuration),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      color: playerProvider.isShuffled
                          ? AppColors.primary
                          : (isDark ? Colors.grey[600] : Colors.grey[400]),
                      iconSize: 24,
                      onPressed: () => playerProvider.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      color: isDark ? Colors.white : Colors.black,
                      iconSize: 40,
                      onPressed: () => playerProvider.previous(),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.spotifyGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          playerProvider.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        color: Colors.white,
                        iconSize: 40,
                        onPressed: () => playerProvider.togglePlayPause(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      color: isDark ? Colors.white : Colors.black,
                      iconSize: 40,
                      onPressed: () => playerProvider.next(),
                    ),
                    IconButton(
                      icon: Icon(
                        playerProvider.repeatMode == LoopMode.off
                            ? Icons.repeat
                            : playerProvider.repeatMode == LoopMode.all
                                ? Icons.repeat
                                : Icons.repeat_one,
                      ),
                      color: playerProvider.repeatMode != LoopMode.off
                          ? AppColors.primary
                          : (isDark ? Colors.grey[600] : Colors.grey[400]),
                      iconSize: 24,
                      onPressed: () => playerProvider.toggleRepeat(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Additional Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.devices_outlined),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
