import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/podcast_model.dart';
import '../../providers/podcast_provider.dart';
import 'episode_player_screen.dart';

class PodcastDetailScreen extends StatelessWidget {
  const PodcastDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final podcastProvider = Provider.of<PodcastProvider>(context);
    final podcast = podcastProvider.selectedPodcast;

    if (podcast == null) {
      return const Scaffold(body: Center(child: Text('No podcast selected')));
    }

    final isSubscribed = podcastProvider.isSubscribed(podcast.id);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App bar with podcast art
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B35),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6B35), Color(0xFFFF0099)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            podcast.title[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        podcast.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        podcast.publisher,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Subscribe button & stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => podcastProvider.toggleSubscribe(podcast.id),
                          icon: Icon(isSubscribed
                              ? Icons.check_rounded
                              : Icons.add_rounded),
                          label: Text(isSubscribed ? 'Subscribed' : 'Subscribe'),
                          style: FilledButton.styleFrom(
                            backgroundColor: isSubscribed
                                ? Colors.grey[700]
                                : AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.share_rounded),
                        ),
                      ),
                    ],
                  ),

                  if (podcast.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      podcast.description!,
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.headphones_rounded,
                        label: '${podcast.subscribers} subscribers',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.star_rounded,
                        label: '${podcast.averageRating.toStringAsFixed(1)} rating',
                        color: Colors.amber,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Episodes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Episodes list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _EpisodeTile(
                episode: podcast.episodes[i],
                isDark: isDark,
                podcastProvider: podcastProvider,
                onPlay: () {
                  podcastProvider.playEpisode(podcast.episodes[i]);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: podcastProvider,
                        child: const EpisodePlayerScreen(),
                      ),
                    ),
                  );
                },
              ),
              childCount: podcast.episodes.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool isDark;
  final PodcastProvider podcastProvider;
  final VoidCallback onPlay;

  const _EpisodeTile({
    required this.episode,
    required this.isDark,
    required this.podcastProvider,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final progress = podcastProvider.getProgressFraction(episode);
    final isBookmarked = podcastProvider.isBookmarked(episode.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  episode.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked ? AppColors.primary : Colors.grey,
                  size: 22,
                ),
                onPressed: () => podcastProvider.toggleBookmark(episode.id),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            episode.description,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Progress bar
          if (progress > 0)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                episode.formattedDuration,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onPlay,
                icon: Icon(
                  progress > 0 ? Icons.play_circle_outline_rounded : Icons.play_arrow_rounded,
                  size: 16,
                ),
                label: Text(progress > 0 ? 'Continue' : 'Play',
                    style: const TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(80, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
