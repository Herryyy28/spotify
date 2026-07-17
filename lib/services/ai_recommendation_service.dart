import 'package:harmony_music/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

/// AI-powered recommendation service for personalized music suggestions
class AIRecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mood categories with associated attributes
  static const Map<String, Map<String, dynamic>> moodProfiles = {
    'happy': {'energy': 0.7, 'valence': 0.8, 'tempo': 120},
    'sad': {'energy': 0.3, 'valence': 0.2, 'tempo': 80},
    'energetic': {'energy': 0.9, 'valence': 0.7, 'tempo': 140},
    'calm': {'energy': 0.3, 'valence': 0.5, 'tempo': 70},
    'romantic': {'energy': 0.4, 'valence': 0.6, 'tempo': 90},
    'workout': {'energy': 0.95, 'valence': 0.7, 'tempo': 150},
    'focus': {'energy': 0.5, 'valence': 0.5, 'tempo': 100},
    'party': {'energy': 0.9, 'valence': 0.9, 'tempo': 128},
  };

  /// Get personalized recommendations based on user listening history
  Future<List<Song>> getPersonalizedRecommendations(
    String userId, {
    int limit = 20,
  }) async {
    try {
      // Get user's listening history
      final historySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      if (historySnapshot.docs.isEmpty) {
        // If no history, return popular songs
        return await _getPopularSongs(limit);
      }

      // Extract genres and artists from history
      final genres = <String>{};
      final artists = <String>{};

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        if (data['genre'] != null) genres.add(data['genre']);
        if (data['artist'] != null) artists.add(data['artist']);
      }

      // Get recommendations based on genres and artists
      final recommendations = await _getRecommendationsByGenresAndArtists(
        genres.toList(),
        artists.toList(),
        limit,
      );

      return recommendations;
    } catch (e) {
      AppLogger.error('Error getting personalized recommendations: $e');
      return [];
    }
  }

  /// Get similar songs based on a seed song
  Future<List<Song>> getSimilarSongs(
    Song seedSong, {
    int limit = 10,
  }) async {
    try {
      final recommendations = <Song>[];

      // Find songs by same artist
      final artistSongs = await _firestore
          .collection('songs')
          .where('artist', isEqualTo: seedSong.artist)
          .where('id', isNotEqualTo: seedSong.id)
          .limit(5)
          .get();

      for (var doc in artistSongs.docs) {
        recommendations.add(Song.fromMap(doc.data()));
      }

      // Find songs in same genre
      if (recommendations.length < limit) {
        final genreSongs = await _firestore
            .collection('songs')
            .where('genre', isEqualTo: seedSong.genre)
            .limit(limit - recommendations.length)
            .get();

        for (var doc in genreSongs.docs) {
          final song = Song.fromMap(doc.data());
          if (!recommendations.any((s) => s.id == song.id)) {
            recommendations.add(song);
          }
        }
      }

      return recommendations.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting similar songs: $e');
      return [];
    }
  }

  /// Get recommendations based on mood
  Future<List<Song>> getRecommendationsByMood(
    String mood, {
    int limit = 20,
  }) async {
    try {
      final moodProfile = moodProfiles[mood.toLowerCase()];
      if (moodProfile == null) {
        return await _getPopularSongs(limit);
      }

      // For now, we'll use genre-based filtering
      // In a real app, you'd analyze audio features
      final moodGenres = _getGenresForMood(mood);

      final songs = <Song>[];
      for (var genre in moodGenres) {
        final snapshot = await _firestore
            .collection('songs')
            .where('genre', isEqualTo: genre)
            .limit((limit / moodGenres.length).ceil())
            .get();

        for (var doc in snapshot.docs) {
          songs.add(Song.fromMap(doc.data()));
        }
      }

      // Shuffle for variety
      songs.shuffle();
      return songs.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting mood recommendations: $e');
      return [];
    }
  }

  /// Get time-based recommendations (morning, afternoon, evening, night)
  Future<List<Song>> getTimeBasedRecommendations({
    int limit = 20,
  }) async {
    final hour = DateTime.now().hour;
    String mood;

    if (hour >= 5 && hour < 12) {
      mood = 'energetic'; // Morning
    } else if (hour >= 12 && hour < 17) {
      mood = 'focus'; // Afternoon
    } else if (hour >= 17 && hour < 22) {
      mood = 'happy'; // Evening
    } else {
      mood = 'calm'; // Night
    }

    return await getRecommendationsByMood(mood, limit: limit);
  }

  /// Generate a smart playlist based on a theme
  Future<Playlist> generateSmartPlaylist(
    String theme,
    String userId, {
    int songCount = 30,
  }) async {
    try {
      List<Song> songs;

      // Determine playlist type
      if (moodProfiles.containsKey(theme.toLowerCase())) {
        songs = await getRecommendationsByMood(theme, limit: songCount);
      } else {
        songs = await getPersonalizedRecommendations(userId, limit: songCount);
      }

      // Create playlist
      final playlist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '$theme Mix',
        description: 'AI-generated playlist based on $theme',
        coverUrl: songs.isNotEmpty ? songs.first.coverUrl : null,
        userId: userId,
        userName: 'AI DJ',
        songs: songs,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublic: false,
      );

      return playlist;
    } catch (e) {
      AppLogger.error('Error generating smart playlist: $e');
      rethrow;
    }
  }

  /// Get "Discover Weekly" style recommendations
  Future<List<Song>> getDiscoverWeekly(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final recommendations = await getPersonalizedRecommendations(
        userId,
        limit: limit * 2,
      );

      // Filter out songs user has already heard
      final heardSongs = await _getUserHeardSongs(userId);
      final newSongs = recommendations
          .where((song) => !heardSongs.contains(song.id))
          .take(limit)
          .toList();

      return newSongs;
    } catch (e) {
      AppLogger.error('Error getting discover weekly: $e');
      return [];
    }
  }

  /// Get daily mix playlists (like Spotify's Daily Mix 1-6)
  Future<List<Playlist>> getDailyMixes(
    String userId, {
    int mixCount = 6,
  }) async {
    try {
      final mixes = <Playlist>[];

      // Get user's top genres
      final topGenres = await _getUserTopGenres(userId);

      for (int i = 0; i < mixCount && i < topGenres.length; i++) {
        final genre = topGenres[i];
        final songs = await _firestore
            .collection('songs')
            .where('genre', isEqualTo: genre)
            .limit(50)
            .get();

        final songList =
            songs.docs.map((doc) => Song.fromMap(doc.data())).toList();
        songList.shuffle();

        mixes.add(Playlist(
          id: 'daily_mix_${i + 1}',
          name: 'Daily Mix ${i + 1}',
          description: 'Your daily mix of $genre',
          coverUrl: songList.isNotEmpty ? songList.first.coverUrl : null,
          userId: userId,
          userName: 'AI DJ',
          songs: songList.take(30).toList(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isPublic: false,
        ));
      }

      return mixes;
    } catch (e) {
      AppLogger.error('Error getting daily mixes: $e');
      return [];
    }
  }

  // Helper methods

  Future<List<Song>> _getPopularSongs(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('songs')
          .orderBy('playCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Song.fromMap(doc.data())).toList();
    } catch (e) {
      // If playCount field doesn't exist, just get random songs
      final snapshot = await _firestore.collection('songs').limit(limit).get();

      return snapshot.docs.map((doc) => Song.fromMap(doc.data())).toList();
    }
  }

  Future<List<Song>> _getRecommendationsByGenresAndArtists(
    List<String> genres,
    List<String> artists,
    int limit,
  ) async {
    final recommendations = <Song>[];

    // Get songs from favorite genres
    if (genres.isNotEmpty) {
      for (var genre in genres.take(3)) {
        final snapshot = await _firestore
            .collection('songs')
            .where('genre', isEqualTo: genre)
            .limit((limit / 2 / genres.length).ceil())
            .get();

        for (var doc in snapshot.docs) {
          recommendations.add(Song.fromMap(doc.data()));
        }
      }
    }

    // Get songs from favorite artists
    if (artists.isNotEmpty) {
      for (var artist in artists.take(3)) {
        final snapshot = await _firestore
            .collection('songs')
            .where('artist', isEqualTo: artist)
            .limit((limit / 2 / artists.length).ceil())
            .get();

        for (var doc in snapshot.docs) {
          final song = Song.fromMap(doc.data());
          if (!recommendations.any((s) => s.id == song.id)) {
            recommendations.add(song);
          }
        }
      }
    }

    recommendations.shuffle();
    return recommendations.take(limit).toList();
  }

  List<String> _getGenresForMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return ['Pop', 'Dance', 'Indie'];
      case 'sad':
        return ['Indie', 'Alternative', 'Classical'];
      case 'energetic':
        return ['Electronic', 'Rock', 'Hip Hop'];
      case 'calm':
        return ['Classical', 'Ambient', 'Jazz'];
      case 'romantic':
        return ['R&B', 'Soul', 'Pop'];
      case 'workout':
        return ['Electronic', 'Hip Hop', 'Rock'];
      case 'focus':
        return ['Classical', 'Ambient', 'Lo-fi'];
      case 'party':
        return ['Dance', 'Hip Hop', 'Electronic'];
      default:
        return ['Pop', 'Rock', 'Hip Hop'];
    }
  }

  Future<Set<String>> _getUserHeardSongs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .get();

      return snapshot.docs.map((doc) => doc.data()['songId'] as String).toSet();
    } catch (e) {
      return {};
    }
  }

  Future<List<String>> _getUserTopGenres(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .limit(100)
          .get();

      final genreCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final genre = doc.data()['genre'] as String?;
        if (genre != null) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }

      final sortedGenres = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedGenres.map((e) => e.key).toList();
    } catch (e) {
      return ['Pop', 'Rock', 'Hip Hop', 'Electronic', 'Indie', 'R&B'];
    }
  }
}
