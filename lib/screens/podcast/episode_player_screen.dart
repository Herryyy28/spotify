import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/podcast_provider.dart';

class EpisodePlayerScreen extends StatefulWidget {
  const EpisodePlayerScreen({super.key});

  @override
  State<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends State<EpisodePlayerScreen> {
  bool _isPlaying = false;
  double _position = 0.0;
  double _speed = 1.0;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final podcastProvider = Provider.of<PodcastProvider>(context);
    final episode = podcastProvider.currentEpisode;

    if (episode == null) {
      return const Scaffold(body: Center(child: Text('No episode selected')));
    }

    final totalDuration = episode.duration;
    final positionDuration = Duration(seconds: (_position * totalDuration).round());

    String fmt(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return h > 0 ? '$h:$m:$s' : '$m:$s';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF220011), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              color: Color(0xFFFF6B35),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Podcast Episode',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        podcastProvider.isBookmarked(episode.id)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: podcastProvider.isBookmarked(episode.id)
                            ? const Color(0xFFFF6B35)
                            : Colors.white,
                        size: 26,
                      ),
                      onPressed: () => podcastProvider.toggleBookmark(episode.id),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Episode art
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF0099)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    episode.title[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      episode.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${episode.formattedDuration} episode',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        activeTrackColor: const Color(0xFFFF6B35),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: _position.clamp(0.0, 1.0),
                        onChanged: (v) => setState(() => _position = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fmt(positionDuration),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                          Text(fmt(Duration(seconds: totalDuration)),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Skip & Play controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Skip back 15s
                    _SkipButton(
                      icon: Icons.fast_rewind_rounded,
                      label: '-15s',
                      onTap: () {
                        setState(() {
                          _position = (_position - 15 / totalDuration).clamp(0.0, 1.0);
                        });
                      },
                    ),
                    // Play/Pause
                    GestureDetector(
                      onTap: () => setState(() => _isPlaying = !_isPlaying),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF0099)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    // Skip forward 30s
                    _SkipButton(
                      icon: Icons.fast_forward_rounded,
                      label: '+30s',
                      onTap: () {
                        setState(() {
                          _position = (_position + 30 / totalDuration).clamp(0.0, 1.0);
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Speed control
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: _speeds.map((s) {
                    final isSelected = (_speed - s).abs() < 0.01;
                    return GestureDetector(
                      onTap: () => setState(() => _speed = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF6B35)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$s×',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SkipButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              )),
        ],
      ),
    );
  }
}
