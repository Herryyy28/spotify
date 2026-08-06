import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:harmony_music/models/song_model.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/player_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/colors.dart';
import '../player/player_screen.dart';
import 'search_screen.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/playlist_card.dart';
import '../../widgets/home/home_sliver_app_bar.dart';
import '../../widgets/home/hero_carousel_section.dart';
import '../../widgets/home/quick_picks_section.dart';
import '../../widgets/home/recently_played_section.dart';
import '../../widgets/home/recommended_playlists_section.dart';
import '../../core/utils/logger.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const HomeScreen({super.key, this.scaffoldKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load data for all tabs
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      musicProvider.loadInitialData();
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final bool isExpanded = _scrollController.offset < 100;
      if (isExpanded != _isAppBarExpanded) {
        setState(() => _isAppBarExpanded = isExpanded);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final isAdmin = userProvider.isAdmin;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ========== PREMIUM SLIVER APP BAR ==========
          HomeSliverAppBar(
            isAdmin: isAdmin,
            isDark: isDark,
            tabController: _tabController,
            greeting: _getGreeting(),
            scaffoldKey: widget.scaffoldKey,
          ),

          // ========== TAB CONTENT ==========
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForYouTab(),
                _buildNewHitsTab(),
                _buildChartsTab(),
                _buildGenresTab(),
              ],
            ),
          ),
        ],
      ),

      // ========== MINI PLAYER ==========
      floatingActionButton: Consumer<PlayerProvider>(
        builder: (context, playerProvider, _) {
          if (playerProvider.currentSong != null) {
            return _buildMiniPlayer(context);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ========== TAB CONTENT BUILDERS ==========

  Widget _buildForYouTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Quick Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.elevatedDark : Colors.grey[100]!)
                        .withValues(alpha: 0.9),
                    (isDark ? AppColors.cardDark : Colors.grey[50]!)
                        .withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search songs, artists, albums...',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.spotifyGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Voice',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Featured carousel
        HeroCarouselSection(tabController: _tabController),

        const SizedBox(height: 24),

        // Quick Picks
        const QuickPicksSection(),

        const SizedBox(height: 24),

        // Recently Played
        RecentlyPlayedSection(
          onPlaySong: _playSong,
        ),

        const SizedBox(height: 24),

        // Recommended Playlists
        const RecommendedPlaylistsSection(),

        const SizedBox(height: 80), // Space for mini player
      ],
    );
  }

  Widget _buildNewHitsTab() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final newHits = musicProvider.featuredSongs;
        if (musicProvider.isLoading && newHits.isEmpty) {
          return _buildLoadingShimmer();
        }
        if (newHits.isEmpty) {
          return const Center(child: Text('No new hits available.'));
        }
        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: newHits.length,
            itemBuilder: (context, index) {
              final song = newHits[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  child: FadeInAnimation(
                    child: SongTile(
                      song: song,
                      isPlaying: Provider.of<PlayerProvider>(context)
                              .currentSong
                              ?.id ==
                          song.id,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChartsTab() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final charts = musicProvider.charts;
        if (musicProvider.isLoading && charts.isEmpty) {
          return _buildLoadingShimmer();
        }
        if (charts.isEmpty) {
          return const Center(child: Text('No charts available.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: charts.length,
          itemBuilder: (context, index) {
            final playlist = charts[index];
            return PlaylistCard(playlist: playlist);
          },
        );
      },
    );
  }

  Widget _buildGenresTab() {
    final genres = [
      'Pop',
      'Rock',
      'Hip-Hop',
      'Electronic',
      'Jazz',
      'Classical',
      'R&B',
      'Country'
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        return _buildGenreCard(genres[index], index);
      },
    );
  }

  Widget _buildGenreCard(String genre, int index) {
    final gradient = AppColors.genreGradients[genre] ??
        AppColors.popularGradients[index % AppColors.popularGradients.length];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gradient,
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      genre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Explore',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== MINI PLAYER ==========

  Widget _buildMiniPlayer(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final song = playerProvider.currentSong!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 72,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openPlayerScreen(song),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Hero(
                      tag: 'song_art_${song.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: song.coverUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                          onPressed: () {
                            AppLogger.info('Admin menu for song: ${song.title}');
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        playerProvider.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      onPressed: playerProvider.togglePlayPause,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 28,
                      ),
                      onPressed: playerProvider.next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== HELPER METHODS ==========

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  void _playSong(Song song) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playSong(song);
    _openPlayerScreen(song);
  }

  void _openPlayerScreen(Song song) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PlayerScreen(song: song),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
      ),
    );
  }

  // ========== SHIMMER LOADING STATES ==========

  Widget _buildLoadingShimmer() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
