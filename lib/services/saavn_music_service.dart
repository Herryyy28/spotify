import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/song_model.dart';
import '../core/utils/logger.dart';

class SaavnMusicService {
  static const String _baseUrl = 'https://saavn.dev/api';
  final Dio _dio = Dio();

  /// Searches songs on JioSaavn and maps them to [Song] models with full 320kbps audio URLs.
  Future<List<Song>> searchSongs(String query, {int limit = 20}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl/search/songs?query=$encodedQuery&limit=$limit';
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data is String ? json.decode(response.data) : response.data;
        final List<dynamic> results = data['data']?['results'] ?? [];

        return results.map((item) => _mapToSong(item)).where((song) => song.audioUrl.isNotEmpty).toList();
      }
    } catch (e) {
      AppLogger.error('Error searching songs on Saavn API: $e');
    }
    return [];
  }

  /// Fetches popular/trending songs for initial homepage music feed.
  Future<List<Song>> fetchTrendingSongs({String query = 'pop', int limit = 25}) async {
    return searchSongs(query, limit: limit);
  }

  /// Fetches lyrics for a song by ID if available.
  Future<String?> fetchLyrics(String songId) async {
    try {
      final url = '$_baseUrl/songs/$songId/lyrics';
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data is String ? json.decode(response.data) : response.data;
        return data['data']?['lyrics'];
      }
    } catch (e) {
      AppLogger.error('Error fetching lyrics from Saavn API: $e');
    }
    return null;
  }

  /// Helper to convert Saavn JSON response into standard [Song] model.
  Song _mapToSong(Map<String, dynamic> item) {
    // Extract highest quality audio stream URL (usually 320kbps or last in list)
    final List<dynamic> downloadUrls = item['downloadUrl'] ?? [];
    String audioUrl = '';
    if (downloadUrls.isNotEmpty) {
      // Pick 320kbps or the highest available quality stream
      final highQuality = downloadUrls.firstWhere(
        (element) => element['quality'] == '320kbps',
        orElse: () => downloadUrls.last,
      );
      audioUrl = highQuality['url'] ?? '';
    }

    // Extract highest resolution cover art (usually 500x500 or last in list)
    final List<dynamic> images = item['image'] ?? [];
    String coverUrl = 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80';
    if (images.isNotEmpty) {
      coverUrl = images.last['url'] ?? coverUrl;
    }

    // Calculate duration
    final int durationInSec = int.tryParse(item['duration']?.toString() ?? '180') ?? 180;
    final int minutes = durationInSec ~/ 60;
    final int seconds = durationInSec % 60;
    final String formattedDuration = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Song(
      id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: item['name'] ?? item['title'] ?? 'Unknown Track',
      artist: item['primaryArtists'] ?? item['artist'] ?? 'Unknown Artist',
      album: (item['album'] is Map ? item['album']['name'] : item['album']) ?? 'Single',
      duration: formattedDuration,
      durationInSeconds: durationInSec,
      audioUrl: audioUrl,
      coverUrl: coverUrl,
      genres: [item['language'] ?? 'Pop'],
      releaseDate: DateTime.now(),
      isExplicit: item['explicitContent'] == true || item['explicitContent'] == 1,
      copyright: item['label'] ?? '',
    );
  }
}
