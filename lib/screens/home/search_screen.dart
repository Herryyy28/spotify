import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/player_provider.dart';
import '../../models/song_model.dart';
import '../../models/artist_model.dart';
import '../../models/playlist_model.dart';
import '../../widgets/song_tile.dart';
import '../../core/theme/colors.dart';
import '../player/player_screen.dart';
import '../../core/widgets/harmony_text_field.dart';
import '../../providers/search_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = ['All', 'Songs', 'Artists', 'Playlists'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchProvider = Provider.of<SearchProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Search Bar with Glassmorphism
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                        .withValues(alpha: 0.95),
                    (isDark ? AppColors.cardDark : AppColors.cardLight)
                        .withValues(alpha: 0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: HarmonyTextField(
                      controller: _searchController,
                      hintText: 'Search songs, artists, albums...',
                      prefixIcon: Icons.search_rounded,
                      onChanged: searchProvider.performSearch,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              onPressed: () {
                                _searchController.clear();
                                searchProvider.performSearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                  if (searchProvider.isSearching) ...[
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          _searchController.clear();
                          searchProvider.performSearch('');
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Filter Chips
            if (searchProvider.isSearching)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = searchProvider.selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) {
                            searchProvider.setFilter(filter);
                          },
                          backgroundColor: theme.cardColor,
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : null,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Search Results
            Expanded(
              child: _buildSearchResults(searchProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (!searchProvider.isSearching) {
      return ListView(
        children: [
          _buildRecentSearches(searchProvider),
          _buildBrowseCategories(),
        ],
      );
    }

    if (searchProvider.isLoading) {
      return _buildShimmerLoading();
    }

    if (searchProvider.songResults.isEmpty && searchProvider.artistResults.isEmpty && searchProvider.playlistResults.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Result
        if (searchProvider.selectedFilter == 'All' && searchProvider.songResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Top Result',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildTopResult(searchProvider.songResults.first),
          const SizedBox(height: 24),
        ],

        // Songs
        if (searchProvider.selectedFilter == 'All' || searchProvider.selectedFilter == 'Songs')
          if (searchProvider.songResults.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Songs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...searchProvider.songResults.take(5).map((song) => SongTile(
                  song: song,
                  onTap: () => _playSong(song),
                )),
            if (searchProvider.songResults.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton(
                  onPressed: () {
                    searchProvider.setFilter('Songs');
                  },
                  child: const Text('See All Songs'),
                ),
              ),
            const SizedBox(height: 16),
          ],

        // Artists
        if (searchProvider.selectedFilter == 'All' || searchProvider.selectedFilter == 'Artists')
          if (searchProvider.artistResults.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Artists',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: searchProvider.artistResults.length,
                itemBuilder: (context, index) {
                  final artist = searchProvider.artistResults[index];
                  return _buildArtistCard(artist);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

        // Playlists
        if (searchProvider.selectedFilter == 'All' || searchProvider.selectedFilter == 'Playlists')
          if (searchProvider.playlistResults.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Playlists',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...searchProvider.playlistResults.map((playlist) => _buildPlaylistTile(playlist)),
          ],
      ],
    );
  }

  Widget _buildRecentSearches(SearchProvider searchProvider) {
    final theme = Theme.of(context);

    if (searchProvider.recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => searchProvider.clearRecentSearches(),
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: searchProvider.recentSearches.length,
          itemBuilder: (context, index) {
            final search = searchProvider.recentSearches[index];
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(search),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => searchProvider.removeRecentSearch(search),
              ),
              onTap: () {
                _searchController.text = search;
                searchProvider.performSearch(search);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBrowseCategories() {
    final theme = Theme.of(context);
    final categories = [
      {'name': 'Pop', 'color': Colors.pink},
      {'name': 'Rock', 'color': Colors.red},
      {'name': 'Hip-Hop', 'color': Colors.orange},
      {'name': 'Jazz', 'color': Colors.purple},
      {'name': 'Podcasts', 'color': Colors.green},
      {'name': 'Moods', 'color': Colors.blue},
      {'name': 'Workout', 'color': Colors.teal},
      {'name': 'Sleep', 'color': Colors.indigo},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse All',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                decoration: BoxDecoration(
                  color: cat['color'] as Color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopResult(Song song) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            song.coverUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(song.artist),
        trailing: const Icon(
          Icons.play_circle_filled,
          color: AppColors.primary,
          size: 40,
        ),
        onTap: () => _playSong(song),
      ),
    );
  }

  Widget _buildArtistCard(Artist artist) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(artist.imageUrl ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artist.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${artist.getFormattedListeners()} monthly listeners',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          playlist.coverUrl ?? '',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
            child: const Icon(Icons.playlist_play),
          ),
        ),
      ),
      title: Text(playlist.name),
      subtitle: Text('${playlist.songCount} songs • ${playlist.userName}'),
      trailing: const Icon(Icons.play_arrow),
      onTap: () {
        // Navigate to playlist
      },
    );
  }

  void _playSong(Song song) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playSong(song);
    _openPlayerScreen(song);
  }

  void _openPlayerScreen(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(song: song),
      ),
    );
  }

  // _clearRecentSearches is now in provider

  // _removeRecentSearch is now in provider

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
