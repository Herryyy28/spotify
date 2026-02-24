import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/player_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/song_model.dart';
import '../../models/artist_model.dart';
import '../../models/playlist_model.dart';
import '../../widgets/song_tile.dart';
import '../../core/theme/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  List<Song> _songResults = [];
  List<Artist> _artistResults = [];
  List<Playlist> _playlistResults = [];

  bool _isSearching = false;
  bool _isLoading = false;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Songs', 'Artists', 'Playlists'];

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    // Load from shared preferences
    setState(() {
      _recentSearches = [
        'Imagine Dragons',
        'Ed Sheeran',
        'Pop Hits',
        'Workout'
      ];
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _songResults = [];
        _artistResults = [];
        _playlistResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final songs = await _firebaseService.searchSongs(query);
      // Also search artists and playlists

      setState(() {
        _songResults = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                        .withOpacity(0.95),
                    (isDark ? AppColors.cardDark : AppColors.cardLight)
                        .withOpacity(0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isDark
                                    ? AppColors.elevatedDark
                                    : Colors.grey[100]!)
                                .withOpacity(0.8),
                            (isDark ? AppColors.cardDark : Colors.grey[50]!)
                                .withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(
                            _searchController.text.isNotEmpty ? 0.5 : 0.1,
                          ),
                          width: 2,
                        ),
                        boxShadow: _searchController.text.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _performSearch,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search songs, artists, albums...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _searchController.text.isNotEmpty
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400]),
                            size: 24,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
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
            if (_isSearching)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedFilter = filter);
                          },
                          backgroundColor: theme.cardColor,
                          selectedColor: AppColors.primary.withOpacity(0.2),
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
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_isSearching) {
      return _buildRecentSearches();
    }

    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_songResults.isEmpty &&
        _artistResults.isEmpty &&
        _playlistResults.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Result
        if (_selectedFilter == 'All' && _songResults.isNotEmpty) ...[
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
          _buildTopResult(_songResults.first),
          const SizedBox(height: 24),
        ],

        // Songs
        if (_selectedFilter == 'All' || _selectedFilter == 'Songs')
          if (_songResults.isNotEmpty) ...[
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
            ..._songResults.take(5).map((song) => SongTile(
                  song: song,
                  onTap: () => _playSong(song),
                )),
            if (_songResults.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton(
                  onPressed: () {
                    setState(() => _selectedFilter = 'Songs');
                  },
                  child: const Text('See All Songs'),
                ),
              ),
            const SizedBox(height: 16),
          ],

        // Artists
        if (_selectedFilter == 'All' || _selectedFilter == 'Artists')
          if (_artistResults.isNotEmpty) ...[
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
                itemCount: _artistResults.length,
                itemBuilder: (context, index) {
                  final artist = _artistResults[index];
                  return _buildArtistCard(artist);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

        // Playlists
        if (_selectedFilter == 'All' || _selectedFilter == 'Playlists')
          if (_playlistResults.isNotEmpty) ...[
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
            ..._playlistResults.map((playlist) => _buildPlaylistTile(playlist)),
          ],
      ],
    );
  }

  Widget _buildRecentSearches() {
    final theme = Theme.of(context);

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
                onPressed: _clearRecentSearches,
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(search),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _removeRecentSearch(search),
                ),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              );
            },
          ),
        ),
      ],
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
            color: Colors.black.withOpacity(0.05),
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
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.remove(search);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
