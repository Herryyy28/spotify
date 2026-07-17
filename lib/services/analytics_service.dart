import 'package:harmony_music/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_model.dart';

/// Service for tracking and analyzing user listening behavior
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track when a song is played
  Future<void> trackSongPlay(String userId, Song song) async {
    try {
      final timestamp = DateTime.now();

      // Add to listening history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .add({
        'songId': song.id,
        'title': song.title,
        'artist': song.artist,
        'genre': song.genre,
        'timestamp': timestamp,
        'duration': song.duration,
      });

      // Update song play count
      await _firestore.collection('songs').doc(song.id).update({
        'playCount': FieldValue.increment(1),
        'lastPlayed': timestamp,
      });

      // Update user stats
      await _updateUserStats(userId, song);
    } catch (e) {
      AppLogger.error('Error tracking song play: $e');
    }
  }

  /// Get user statistics
  Future<UserStats> getUserStatistics(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get listening history for last 30 days
      final historySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .get();

      final totalSongs = historySnapshot.docs.length;
      var totalMinutes = 0;

      // Calculate total listening time
      for (var doc in historySnapshot.docs) {
        final duration = doc.data()['duration'] as int? ?? 0;
        totalMinutes += (duration ~/ 60);
      }

      // Get top artists
      final topArtists = await _getTopArtists(userId, limit: 5);

      // Get top genres
      final topGenres = await _getTopGenres(userId, limit: 5);

      // Get top songs
      final topSongs = await getTopSongs(userId, limit: 10);

      return UserStats(
        totalSongsPlayed: totalSongs,
        totalListeningMinutes: totalMinutes,
        topArtists: topArtists,
        topGenres: topGenres,
        topSongs: topSongs,
        periodDays: 30,
      );
    } catch (e) {
      AppLogger.error('Error getting user statistics: $e');
      return UserStats.empty();
    }
  }

  /// Get top songs for a user
  Future<List<Song>> getTopSongs(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();

      // Count song plays
      final songCounts = <String, int>{};
      final songData = <String, Map<String, dynamic>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final songId = data['songId'] as String;
        songCounts[songId] = (songCounts[songId] ?? 0) + 1;
        songData[songId] = data;
      }

      // Sort by play count
      final sortedSongs = songCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Fetch full song details
      final topSongs = <Song>[];
      for (var entry in sortedSongs.take(limit)) {
        try {
          final songDoc =
              await _firestore.collection('songs').doc(entry.key).get();

          if (songDoc.exists) {
            topSongs.add(Song.fromMap(songDoc.data()!));
          }
        } catch (e) {
          AppLogger.error('Error fetching song ${entry.key}: $e');
        }
      }

      return topSongs;
    } catch (e) {
      AppLogger.error('Error getting top songs: $e');
      return [];
    }
  }

  /// Get listening patterns (hourly distribution)
  Future<ListeningPatterns> getListeningPatterns(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      final hourlyDistribution = List<int>.filled(24, 0);
      final weekdayDistribution = List<int>.filled(7, 0);

      for (var doc in snapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        hourlyDistribution[timestamp.hour]++;
        weekdayDistribution[timestamp.weekday - 1]++;
      }

      return ListeningPatterns(
        hourlyDistribution: hourlyDistribution,
        weekdayDistribution: weekdayDistribution,
        peakHour: _findPeakIndex(hourlyDistribution),
        peakDay: _findPeakIndex(weekdayDistribution),
      );
    } catch (e) {
      AppLogger.error('Error getting listening patterns: $e');
      return ListeningPatterns.empty();
    }
  }

  /// Get year in review statistics
  Future<YearInReview> getYearInReview(String userId, int year) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .where('timestamp', isGreaterThanOrEqualTo: startOfYear)
          .where('timestamp', isLessThanOrEqualTo: endOfYear)
          .get();

      final totalSongs = snapshot.docs.length;
      var totalMinutes = 0;

      for (var doc in snapshot.docs) {
        final duration = doc.data()['duration'] as int? ?? 0;
        totalMinutes += (duration ~/ 60);
      }

      final topArtists = await _getTopArtists(userId, limit: 5, year: year);
      final topGenres = await _getTopGenres(userId, limit: 5, year: year);
      final topSongs = await _getTopSongsForYear(userId, year, limit: 10);

      return YearInReview(
        year: year,
        totalSongsPlayed: totalSongs,
        totalListeningMinutes: totalMinutes,
        topArtists: topArtists,
        topGenres: topGenres,
        topSongs: topSongs,
      );
    } catch (e) {
      AppLogger.error('Error getting year in review: $e');
      return YearInReview.empty(year);
    }
  }

  // Helper methods

  Future<void> _updateUserStats(String userId, Song song) async {
    try {
      final userStatsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('overall');

      await userStatsRef.set({
        'totalPlays': FieldValue.increment(1),
        'lastPlayed': DateTime.now(),
        'genres': FieldValue.arrayUnion([song.genre]),
        'artists': FieldValue.arrayUnion([song.artist]),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Error updating user stats: $e');
    }
  }

  Future<List<String>> _getTopArtists(
    String userId, {
    int limit = 5,
    int? year,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history');

      if (year != null) {
        final startOfYear = DateTime(year, 1, 1);
        final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: startOfYear)
            .where('timestamp', isLessThanOrEqualTo: endOfYear);
      }

      final snapshot = await query.limit(500).get();

      final artistCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final artist = doc.data()['artist'] as String?;
        if (artist != null) {
          artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
        }
      }

      final sortedArtists = artistCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedArtists.take(limit).map((e) => e.key).toList();
    } catch (e) {
      AppLogger.error('Error getting top artists: $e');
      return [];
    }
  }

  Future<List<String>> _getTopGenres(
    String userId, {
    int limit = 5,
    int? year,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history');

      if (year != null) {
        final startOfYear = DateTime(year, 1, 1);
        final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: startOfYear)
            .where('timestamp', isLessThanOrEqualTo: endOfYear);
      }

      final snapshot = await query.limit(500).get();

      final genreCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final genre = doc.data()['genre'] as String?;
        if (genre != null) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        }
      }

      final sortedGenres = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedGenres.take(limit).map((e) => e.key).toList();
    } catch (e) {
      AppLogger.error('Error getting top genres: $e');
      return [];
    }
  }

  Future<List<Song>> _getTopSongsForYear(
    String userId,
    int year, {
    int limit = 10,
  }) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .where('timestamp', isGreaterThanOrEqualTo: startOfYear)
          .where('timestamp', isLessThanOrEqualTo: endOfYear)
          .get();

      final songCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final songId = doc.data()['songId'] as String;
        songCounts[songId] = (songCounts[songId] ?? 0) + 1;
      }

      final sortedSongs = songCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topSongs = <Song>[];
      for (var entry in sortedSongs.take(limit)) {
        try {
          final songDoc =
              await _firestore.collection('songs').doc(entry.key).get();

          if (songDoc.exists) {
            topSongs.add(Song.fromMap(songDoc.data()!));
          }
        } catch (e) {
          AppLogger.error('Error fetching song: $e');
        }
      }

      return topSongs;
    } catch (e) {
      AppLogger.error('Error getting top songs for year: $e');
      return [];
    }
  }

  int _findPeakIndex(List<int> distribution) {
    int maxIndex = 0;
    int maxValue = distribution[0];

    for (int i = 1; i < distribution.length; i++) {
      if (distribution[i] > maxValue) {
        maxValue = distribution[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }
}

// Data models for analytics

class UserStats {
  final int totalSongsPlayed;
  final int totalListeningMinutes;
  final List<String> topArtists;
  final List<String> topGenres;
  final List<Song> topSongs;
  final int periodDays;

  UserStats({
    required this.totalSongsPlayed,
    required this.totalListeningMinutes,
    required this.topArtists,
    required this.topGenres,
    required this.topSongs,
    required this.periodDays,
  });

  factory UserStats.empty() => UserStats(
        totalSongsPlayed: 0,
        totalListeningMinutes: 0,
        topArtists: [],
        topGenres: [],
        topSongs: [],
        periodDays: 30,
      );

  int get totalListeningHours => totalListeningMinutes ~/ 60;
}

class ListeningPatterns {
  final List<int> hourlyDistribution;
  final List<int> weekdayDistribution;
  final int peakHour;
  final int peakDay;

  ListeningPatterns({
    required this.hourlyDistribution,
    required this.weekdayDistribution,
    required this.peakHour,
    required this.peakDay,
  });

  factory ListeningPatterns.empty() => ListeningPatterns(
        hourlyDistribution: List.filled(24, 0),
        weekdayDistribution: List.filled(7, 0),
        peakHour: 0,
        peakDay: 0,
      );

  String get peakHourFormatted {
    final hour = peakHour % 12 == 0 ? 12 : peakHour % 12;
    final period = peakHour < 12 ? 'AM' : 'PM';
    return '$hour $period';
  }

  String get peakDayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[peakDay];
  }
}

class YearInReview {
  final int year;
  final int totalSongsPlayed;
  final int totalListeningMinutes;
  final List<String> topArtists;
  final List<String> topGenres;
  final List<Song> topSongs;

  YearInReview({
    required this.year,
    required this.totalSongsPlayed,
    required this.totalListeningMinutes,
    required this.topArtists,
    required this.topGenres,
    required this.topSongs,
  });

  factory YearInReview.empty(int year) => YearInReview(
        year: year,
        totalSongsPlayed: 0,
        totalListeningMinutes: 0,
        topArtists: [],
        topGenres: [],
        topSongs: [],
      );

  int get totalListeningHours => totalListeningMinutes ~/ 60;
}
