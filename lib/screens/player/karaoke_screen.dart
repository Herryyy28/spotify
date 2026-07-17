import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../providers/player_provider.dart';

class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({super.key});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Sample synced lyrics — in production these come from the lyrics service
  final List<_LyricLine> _lines = const [
    _LyricLine(startSec: 0, text: '♪ ♪ ♪'),
    _LyricLine(startSec: 5, text: 'Let the music carry you away'),
    _LyricLine(startSec: 10, text: 'Feel the rhythm, feel the beat'),
    _LyricLine(startSec: 15, text: 'Every note is bittersweet'),
    _LyricLine(startSec: 20, text: 'Close your eyes and just believe'),
    _LyricLine(startSec: 25, text: 'This is what you want to feel'),
    _LyricLine(startSec: 30, text: 'Let the music carry you away'),
    _LyricLine(startSec: 35, text: 'Higher, higher, higher'),
    _LyricLine(startSec: 40, text: 'Dance until the break of dawn'),
    _LyricLine(startSec: 45, text: 'Every beat goes on and on'),
    _LyricLine(startSec: 50, text: '♪ ♪ ♪'),
  ];

  final ScrollController _scrollController = ScrollController();
  int _activeIndex = 0;
  static const double _lineHeight = 72.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateActiveIndex(int positionSec) {
    int idx = 0;
    for (int i = 0; i < _lines.length; i++) {
      if (positionSec >= _lines[i].startSec) {
        idx = i;
      } else {
        break;
      }
    }
    if (idx != _activeIndex) {
      setState(() => _activeIndex = idx);
      _scrollToActive(idx);
    }
  }

  void _scrollToActive(int idx) {
    if (!_scrollController.hasClients) return;
    final target = (idx * _lineHeight) - 200.0;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final song = playerProvider.currentSong;
    final positionSec = playerProvider.currentPosition.inSeconds;

    // Update active lyric index
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateActiveIndex(positionSec));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background with blur
          if (song?.coverUrl != null)
            Positioned.fill(
              child: Image.network(
                song!.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),

          // Dark overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withValues(alpha: 0.82)),
            ),
          ),

          // Gradient glow at active line area
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (_, __) => Positioned(
              top: MediaQuery.of(context).size.height * 0.38,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: _glowAnimation.value * 0.25),
                      Colors.transparent,
                    ],
                    radius: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          const Text(
                            'KARAOKE MODE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            song?.title ?? '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 24),
                      ),
                    ],
                  ),
                ),

                // Lyrics scroll view
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: MediaQuery.of(context).size.height * 0.2,
                    ),
                    itemCount: _lines.length,
                    itemBuilder: (_, i) => _buildLyricLine(i),
                  ),
                ),

                // Mini playback controls
                _buildMiniControls(playerProvider),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricLine(int i) {
    final isActive = i == _activeIndex;
    final isPast = i < _activeIndex;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontSize: isActive ? 28 : 20,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
        color: isActive
            ? Colors.white
            : isPast
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.45),
        height: 1.4,
        shadows: isActive
            ? [
                Shadow(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  blurRadius: 20,
                ),
                Shadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 40,
                ),
              ]
            : null,
      ),
      child: Container(
        height: _lineHeight,
        alignment: Alignment.center,
        child: Text(
          _lines[i].text,
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildMiniControls(PlayerProvider playerProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 30),
            onPressed: () => playerProvider.previous(),
          ),
          GestureDetector(
            onTap: () => playerProvider.togglePlayPause(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.neonPurple],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(
                playerProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
            onPressed: () => playerProvider.next(),
          ),
        ],
      ),
    );
  }
}

class _LyricLine {
  final int startSec;
  final String text;
  const _LyricLine({required this.startSec, required this.text});
}
