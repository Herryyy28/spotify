import 'package:harmony_music/core/utils/logger.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_model.dart';
import 'firebase_service.dart';

class RecommendationService {
  final FirebaseService _firebaseService = FirebaseService();

  // Get personalized recommendations
  Future<List<Song>> getPersonalizedRecommendations(String userId) async {
    try {
      // Get user's listening history
      final history = await _getUserListeningHistory(userId);

      if (history.isEmpty) {
        return _getNewUserRecommendations();
      }

      // Get user's favorite genres
      final favoriteGenres = await _getFavoriteGenres(userId, history);

      // Get user's favorite artists
      final favoriteArtists = await _getFavoriteArtists(userId, history);

      // Get collaborative filtering recommendations
      final collaborativeRecs = await _getCollaborativeRecommendations(userId);

      // Get content-based recommendations
      final contentBasedRecs = await _getContentBasedRecommendations(
        history,
        favoriteGenres,
        favoriteArtists,
      );

      // Merge and rank recommendations
      final recommendations = _mergeRecommendations([
        collaborativeRecs,
        contentBasedRecs,
      ]);

      return recommendations.take(30).toList();
    } catch (e) {
      AppLogger.error('Error getting recommendations: $e');
      return [];
    }
  }

  // Get daily mix
  Future<List<Song>> getDailyMix(String userId) async {
    try {
      final recommendations = await getPersonalizedRecommendations(userId);
      final shuffled = List<Song>.from(recommendations);
      shuffled.shuffle();
      return shuffled.take(20).toList();
    } catch (e) {
      AppLogger.error('Error getting daily mix: $e');
      return [];
    }
  }

  // Get recommendations based on song
  Future<List<Song>> getSongRecommendations(Song song) async {
    try {
      // Get songs with similar genres
      final similarGenreSongs = await _firebaseService.getSongs(
        genres: song.genres,
        limit: 20,
      );

      // Get songs by same artist
      final sameArtistSongs = await _firebaseService.getArtistTopSongs(
        song.artistId ?? '',
        limit: 10,
      );

      // Merge and filter out current song
      final recommendations = [
        ...similarGenreSongs,
        ...sameArtistSongs,
      ].where((s) => s.id != song.id).toList();

      // Remove duplicates
      final unique = recommendations
          .fold<Map<String, Song>>({}, (map, song) {
            map[song.id] = song;
            return map;
          })
          .values
          .toList();

      return unique.take(20).toList();
    } catch (e) {
      AppLogger.error('Error getting song recommendations: $e');
      return [];
    }
  }

  // Get recommendations based on playlist
  Future<List<Song>> getPlaylistRecommendations(
      List<Song> playlistSongs) async {
    try {
      if (playlistSongs.isEmpty) return [];

      // Extract features from playlist
      final genres = <String>{};
      final artists = <String>{};
      final averagePopularity =
          playlistSongs.map((s) => s.playCount).reduce((a, b) => a + b) /
              playlistSongs.length;

      for (final song in playlistSongs) {
        genres.addAll(song.genres);
        if (song.artistId != null) {
          artists.add(song.artistId!);
        }
      }

      // Get recommendations based on playlist features
      final recommendations = await _firebaseService.getSongs(
        genres: genres.toList(),
        limit: 50,
      );

      // Score and rank recommendations
      final scoredSongs = recommendations.map((song) {
        double score = 0;

        // Score based on genre match
        final genreMatch = song.genres.where((g) => genres.contains(g)).length;
        score += genreMatch * 0.3;

        // Score based on artist match
        if (artists.contains(song.artistId)) {
          score += 0.5;
        }

        // Score based on popularity
        final popularityScore = min(song.playCount / averagePopularity, 1.0);
        score += popularityScore * 0.2;

        return MapEntry(song, score);
      }).toList();

      // Sort by score
      scoredSongs.sort((a, b) => b.value.compareTo(a.value));

      return scoredSongs
          .where((e) => !playlistSongs.any((s) => s.id == e.key.id))
          .map((e) => e.key)
          .take(20)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting playlist recommendations: $e');
      return [];
    }
  }

  // Get trending songs
  Future<List<Song>> getTrendingSongs() async {
    try {
      // Get songs with most plays in last week
      final snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .orderBy('weeklyPlays', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Song.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error getting trending songs: $e');
      return [];
    }
  }

  // Get user's listening history
  Future<List<Song>> _getUserListeningHistory(String userId) async {
    try {
      return await _firebaseService.getRecentlyPlayed(userId);
    } catch (e) {
      AppLogger.error('Error getting listening history: $e');
      return [];
    }
  }

  // Get user's favorite genres
  Future<List<String>> _getFavoriteGenres(
      String userId, List<Song> history) async {
    final genreCount = <String, int>{};

    for (final song in history) {
      for (final genre in song.genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
    }

    final sorted = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }

  // Get user's favorite artists
  Future<List<String>> _getFavoriteArtists(
      String userId, List<Song> history) async {
    final artistCount = <String, int>{};

    for (final song in history) {
      if (song.artistId != null) {
        artistCount[song.artistId!] = (artistCount[song.artistId!] ?? 0) + 1;
      }
    }

    final sorted = artistCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }

  // Get collaborative filtering recommendations
  Future<List<Song>> _getCollaborativeRecommendations(String userId) async {
    try {
      // Find similar users
      final similarUsers = await _findSimilarUsers(userId);

      // Get songs liked by similar users
      final recommendedSongs = <Song>[];

      for (final otherUserId in similarUsers) {
        final likedSongs = await _getUserLikedSongs(otherUserId);
        recommendedSongs.addAll(likedSongs);
      }

      // Remove duplicates
      final unique = recommendedSongs
          .fold<Map<String, Song>>({}, (map, song) {
            map[song.id] = song;
            return map;
          })
          .values
          .toList();

      return unique;
    } catch (e) {
      AppLogger.error('Error getting collaborative recommendations: $e');
      return [];
    }
  }

  // Find users with similar taste
  Future<List<String>> _findSimilarUsers(String userId) async {
    try {
      final userGenres = await _getFavoriteGenres(userId, []);

      final snapshot =
          await FirebaseFirestore.instance.collection('users').limit(10).get();

      final similarUsers = <String>[];

      for (final doc in snapshot.docs) {
        if (doc.id == userId) continue;

        final otherGenres =
            List<String>.from(doc.data()['favoriteGenres'] ?? []);
        final similarity = _calculateJaccardSimilarity(
          Set.from(userGenres),
          Set.from(otherGenres),
        );

        if (similarity > 0.3) {
          similarUsers.add(doc.id);
        }
      }

      return similarUsers;
    } catch (e) {
      AppLogger.error('Error finding similar users: $e');
      return [];
    }
  }

  // Get content-based recommendations
  Future<List<Song>> _getContentBasedRecommendations(
    List<Song> history,
    List<String> favoriteGenres,
    List<String> favoriteArtists,
  ) async {
    try {
      final recommendations = <Song>[];

      // Get songs from favorite genres
      for (final genre in favoriteGenres.take(3)) {
        final songs = await _firebaseService.getSongs(
          genres: [genre],
          limit: 10,
        );
        recommendations.addAll(songs);
      }

      // Get songs from favorite artists
      for (final artistId in favoriteArtists.take(3)) {
        final songs = await _firebaseService.getArtistTopSongs(artistId);
        recommendations.addAll(songs);
      }

      // Remove duplicates and songs already in history
      final historyIds = history.map((s) => s.id).toSet();
      final unique = recommendations
          .fold<Map<String, Song>>({}, (map, song) {
            if (!historyIds.contains(song.id)) {
              map[song.id] = song;
            }
            return map;
          })
          .values
          .toList();

      return unique;
    } catch (e) {
      AppLogger.error('Error getting content-based recommendations: $e');
      return [];
    }
  }

  // Get recommendations for new users
  Future<List<Song>> _getNewUserRecommendations() async {
    try {
      // Return popular songs for new users
      return await _firebaseService.getPopularSongs(limit: 30);
    } catch (e) {
      AppLogger.error('Error getting new user recommendations: $e');
      return [];
    }
  }

  // Get user's liked songs
  Future<List<Song>> _getUserLikedSongs(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('likedSongs')
          .limit(20)
          .get();

      final songs = <Song>[];
      for (final doc in snapshot.docs) {
        final song = await _firebaseService.getSong(doc.id);
        songs.add(song);
      }

      return songs;
    } catch (e) {
      AppLogger.error('Error getting liked songs: $e');
      return [];
    }
  }

  // Calculate Jaccard similarity
  double _calculateJaccardSimilarity(Set a, Set b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return intersection / union;
  }

  // Merge and rank recommendations
  List<Song> _mergeRecommendations(List<List<Song>> recommendationLists) {
    final songScores = <String, double>{};
    final songMap = <String, Song>{};

    for (final list in recommendationLists) {
      for (int i = 0; i < list.length; i++) {
        final song = list[i];
        songMap[song.id] = song;

        // Score based on position
        final score = 1.0 - (i / list.length) * 0.5;
        songScores[song.id] = (songScores[song.id] ?? 0) + score;
      }
    }

    // Sort by score
    final sorted = songScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => songMap[e.key]!).toList();
  }
}
