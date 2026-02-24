import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';

/// AI-powered recommendations screen
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  String _selectedMood = 'happy';

  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Happy',
      'value': 'happy',
      'icon': Icons.sentiment_very_satisfied,
      'color': const Color(0xFFFFD700)
    },
    {
      'name': 'Energetic',
      'value': 'energetic',
      'icon': Icons.bolt,
      'color': const Color(0xFFFF6B35)
    },
    {
      'name': 'Calm',
      'value': 'calm',
      'icon': Icons.spa,
      'color': const Color(0xFF4ECDC4)
    },
    {
      'name': 'Sad',
      'value': 'sad',
      'icon': Icons.sentiment_dissatisfied,
      'color': const Color(0xFF6C5CE7)
    },
    {
      'name': 'Romantic',
      'value': 'romantic',
      'icon': Icons.favorite,
      'color': const Color(0xFFFF6B9D)
    },
    {
      'name': 'Workout',
      'value': 'workout',
      'icon': Icons.fitness_center,
      'color': const Color(0xFF00D2FF)
    },
    {
      'name': 'Focus',
      'value': 'focus',
      'icon': Icons.psychology,
      'color': const Color(0xFF5F27CD)
    },
    {
      'name': 'Party',
      'value': 'party',
      'icon': Icons.celebration,
      'color': const Color(0xFFEE5A6F)
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final userProvider = context.read<UserProvider>();
    final recommendationProvider = context.read<RecommendationProvider>();

    if (userProvider.user != null) {
      await recommendationProvider.loadRecommendations(userProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Discover',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1DB954).withOpacity(0.4),
                      const Color(0xFF1ED760).withOpacity(0.2),
                      const Color(0xFF121212),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.explore,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Consumer<RecommendationProvider>(
              builder: (context, recommendationProvider, child) {
                if (recommendationProvider.isLoading) {
                  return const SizedBox(
                    height: 400,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1DB954),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mood Selector
                    _buildMoodSelector(),
                    const SizedBox(height: 24),

                    // Made For You
                    if (recommendationProvider
                        .personalizedRecommendations.isNotEmpty) ...[
                      _buildSectionHeader('Made For You', Icons.auto_awesome),
                      const SizedBox(height: 12),
                      _buildSongList(
                          recommendationProvider.personalizedRecommendations),
                      const SizedBox(height: 24),
                    ],

                    // Discover Weekly
                    if (recommendationProvider.discoverWeekly.isNotEmpty) ...[
                      _buildSectionHeader('Discover Weekly', Icons.explore),
                      const SizedBox(height: 12),
                      _buildSongList(recommendationProvider.discoverWeekly),
                      const SizedBox(height: 24),
                    ],

                    // Daily Mixes
                    if (recommendationProvider.dailyMixes.isNotEmpty) ...[
                      _buildSectionHeader(
                          'Your Daily Mixes', Icons.queue_music),
                      const SizedBox(height: 12),
                      _buildDailyMixes(recommendationProvider.dailyMixes),
                      const SizedBox(height: 24),
                    ],

                    // Based on Current Time
                    if (recommendationProvider
                        .moodRecommendations.isNotEmpty) ...[
                      _buildSectionHeader(
                        _getTimeBasedTitle(),
                        Icons.schedule,
                      ),
                      const SizedBox(height: 12),
                      _buildSongList(
                          recommendationProvider.moodRecommendations),
                      const SizedBox(height: 24),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _moods.length,
            itemBuilder: (context, index) {
              final mood = _moods[index];
              final isSelected = _selectedMood == mood['value'];

              return GestureDetector(
                onTap: () async {
                  setState(() {
                    _selectedMood = mood['value'];
                  });

                  final userProvider = context.read<UserProvider>();
                  final recommendationProvider =
                      context.read<RecommendationProvider>();

                  if (userProvider.user != null) {
                    await recommendationProvider
                        .getRecommendationsByMood(mood['value']);
                  }
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              mood['color'],
                              mood['color'].withOpacity(0.6),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? mood['color']
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mood['icon'],
                        color: isSelected ? Colors.white : mood['color'],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mood['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1DB954), size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList(List<Song> songs) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return _buildSongCard(song, songs);
        },
      ),
    );
  }

  Widget _buildSongCard(Song song, List<Song> playlist) {
    return GestureDetector(
      onTap: () {
        context.read<PlayerProvider>().playSong(song, playlist: playlist);
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: song.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(song.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: song.imageUrl.isEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Play button overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Song Title
            Text(
              song.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Artist
            Text(
              song.artist,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMixes(List<Playlist> mixes) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mixes.length,
        itemBuilder: (context, index) {
          final mix = mixes[index];
          return _buildPlaylistCard(mix);
        },
      ),
    );
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    return GestureDetector(
      onTap: () {
        // Navigate to playlist detail
        // TODO: Implement playlist detail navigation
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Playlist Cover
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: playlist.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(playlist.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: playlist.imageUrl.isEmpty
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF1DB954),
                          Color(0xFF1ED760),
                        ],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1DB954),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Playlist Name
            Text(
              playlist.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Description
            Text(
              playlist.description ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeBasedTitle() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning Mix';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon Vibes';
    } else if (hour >= 17 && hour < 22) {
      return 'Evening Chill';
    } else {
      return 'Late Night Mix';
    }
  }
}
