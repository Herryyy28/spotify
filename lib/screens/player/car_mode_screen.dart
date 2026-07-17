import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/colors.dart';
import '../../providers/player_provider.dart';

class CarModeScreen extends StatefulWidget {
  const CarModeScreen({super.key});

  @override
  State<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends State<CarModeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final song = playerProvider.currentSong;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.directions_car_rounded,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Car Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Volume indicator
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Album art
              AnimatedBuilder(
                animation: playerProvider.isPlaying ? _pulseAnimation : _pulseController,
                builder: (_, __) {
                  return Transform.scale(
                    scale: playerProvider.isPlaying ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: song?.coverUrl != null
                            ? Image.network(
                                song!.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _defaultArt(),
                              )
                            : _defaultArt(),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Song info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      song?.title ?? 'No song playing',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song?.artist ?? '—',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                        thumbColor: Colors.white,
                        overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: playerProvider.progress.clamp(0.0, 1.0),
                        onChanged: (v) => playerProvider.seek(v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            playerProvider.currentTime,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                          ),
                          Text(
                            playerProvider.totalTime,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Large control buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CarButton(
                      icon: Icons.skip_previous_rounded,
                      size: 56,
                      onTap: () => playerProvider.previous(),
                    ),
                    _CarPlayButton(
                      isPlaying: playerProvider.isPlaying,
                      onTap: () => playerProvider.togglePlayPause(),
                    ),
                    _CarButton(
                      icon: Icons.skip_next_rounded,
                      size: 56,
                      onTap: () => playerProvider.next(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Shuffle & Repeat row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CarSmallButton(
                    icon: playerProvider.isShuffled
                        ? Icons.shuffle_on_rounded
                        : Icons.shuffle_rounded,
                    color: playerProvider.isShuffled ? AppColors.primary : Colors.white.withValues(alpha: 0.4),
                    onTap: () => playerProvider.toggleShuffle(),
                  ),
                  const SizedBox(width: 48),
                  _CarSmallButton(
                    icon: playerProvider.repeatMode == LoopMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: playerProvider.repeatMode != LoopMode.off
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.4),
                    onTap: () => playerProvider.toggleRepeat(),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultArt() {
    return Container(
      color: AppColors.cardDark,
      child: const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 80),
    );
  }
}

class _CarButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _CarButton({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class _CarPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _CarPlayButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.neonPurple],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 56,
        ),
      ),
    );
  }
}

class _CarSmallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CarSmallButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
