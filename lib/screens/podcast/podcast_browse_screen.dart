import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../models/podcast_model.dart';
import '../../providers/podcast_provider.dart';
import 'podcast_detail_screen.dart';

class PodcastBrowseScreen extends StatelessWidget {
  const PodcastBrowseScreen({super.key});

  static const List<String> _categories = [
    'All', 'Music', 'Culture', 'Technology', 'Interviews', 'Comedy', 'News',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final podcastProvider = Provider.of<PodcastProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
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
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.podcasts_rounded, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Podcasts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (_, i) => _CategoryChip(
                  label: _categories[i],
                  isSelected: i == 0,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Subscribed
          if (podcastProvider.subscribedPodcasts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Subscribed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: podcastProvider.podcasts
                      .where((p) => podcastProvider.isSubscribed(p.id))
                      .length,
                  itemBuilder: (_, i) {
                    final subscribedPodcasts = podcastProvider.podcasts
                        .where((p) => podcastProvider.isSubscribed(p.id))
                        .toList();
                    return _PodcastCard(
                      podcast: subscribedPodcasts[i],
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // All podcasts
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Popular Shows',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _PodcastListTile(
                podcast: podcastProvider.podcasts[i],
                isDark: isDark,
                isSubscribed: podcastProvider.isSubscribed(podcastProvider.podcasts[i].id),
                onTap: () {
                  podcastProvider.selectPodcast(podcastProvider.podcasts[i]);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: podcastProvider,
                        child: const PodcastDetailScreen(),
                      ),
                    ),
                  );
                },
              ),
              childCount: podcastProvider.podcasts.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected
            ? AppColors.primary
            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide.none,
      ),
    );
  }
}

class _PodcastCard extends StatelessWidget {
  final Podcast podcast;
  final bool isDark;

  const _PodcastCard({required this.podcast, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final provider = Provider.of<PodcastProvider>(context, listen: false);
        provider.selectPodcast(podcast);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const PodcastDetailScreen(),
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B35), Color(0xFFFF0099)],
                ),
              ),
              child: Center(
                child: Text(
                  podcast.title[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              podcast.title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PodcastListTile extends StatelessWidget {
  final Podcast podcast;
  final bool isDark;
  final bool isSubscribed;
  final VoidCallback onTap;

  const _PodcastListTile({
    required this.podcast,
    required this.isDark,
    required this.isSubscribed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF0099)],
                ),
              ),
              child: Center(
                child: Text(
                  podcast.title[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    podcast.publisher,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.headphones_rounded, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${podcast.subscribers} subscribers',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.star_rounded, size: 12, color: Colors.amber[600]),
                      const SizedBox(width: 2),
                      Text(
                        podcast.averageRating.toStringAsFixed(1),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSubscribed)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
