import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../services/firebase_service.dart';

class MusicProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Song> _featuredSongs = [];
  final List<Song> _recentSongs = [];
  List<Song> _popularSongs = [];
  List<Song> _newHits = [];
  List<Playlist> _featuredPlaylists = [];
  List<Playlist> _recommendedPlaylists = [];
  List<Playlist> _charts = [];
  bool _isLoading = false;
  String? _error;

  List<Song> get featuredSongs => _featuredSongs;
  List<Song> get recentSongs => _recentSongs;
  List<Song> get popularSongs => _popularSongs;
  List<Song> get newHits => _newHits;
  List<Playlist> get featuredPlaylists => _featuredPlaylists;
  List<Playlist> get recommendedPlaylists => _recommendedPlaylists;
  List<Playlist> get charts => _charts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalSongs =>
      _popularSongs.length + _newHits.length + _featuredSongs.length;
  int get totalPlaylists =>
      _featuredPlaylists.length + _recommendedPlaylists.length + _charts.length;

  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      // Parallel loading
      final results = await Future.wait([
        _firebaseService.getSongs(limit: 5), // Featured
        _firebaseService.getPopularSongs(limit: 10),
        _firebaseService.getSongs(limit: 10), // New Hits
      ]);

      _featuredSongs = results[0];
      _popularSongs = results[1];
      _newHits = results[2];
      
      // If Firebase is empty (or we're offline), load direct web songs!
      if (_featuredSongs.isEmpty && _popularSongs.isEmpty && _newHits.isEmpty) {
        _loadWebFallbackSongs();
      }

      // For playlists, we'll use empty lists for now
      _featuredPlaylists = [];
      _recommendedPlaylists = [];
      _charts = [];

      _error = null;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error loading music data: $e');
      // On error (like offline), load direct web songs!
      _loadWebFallbackSongs();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadWebFallbackSongs() async {
    try {
      // Fetch 25 popular pop songs from iTunes API
      final response = await http.get(Uri.parse('https://itunes.apple.com/search?term=pop&limit=25&media=music'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        final webSongs = results.map((item) {
          // Get high-res cover art by replacing the 100x100 url
          String coverUrl = item['artworkUrl100'] ?? 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80';
          coverUrl = coverUrl.replaceAll('100x100bb', '500x500bb');
          
          return Song(
            id: item['trackId'].toString(),
            title: item['trackName'] ?? 'Unknown Title',
            artist: item['artistName'] ?? 'Unknown Artist',
            album: item['collectionName'] ?? 'Unknown Album',
            duration: '0:30', // iTunes previews are exactly 30s
            durationInSeconds: 30,
            audioUrl: item['previewUrl'] ?? '',
            coverUrl: coverUrl,
            genres: [item['primaryGenreName'] ?? 'Pop'],
            releaseDate: DateTime.now(), // Simplified
          );
        }).where((song) => song.audioUrl.isNotEmpty).toList();

        // Split them up so the UI looks diverse
        _featuredSongs = webSongs.take(5).toList();
        _popularSongs = webSongs.skip(5).take(10).toList();
        _newHits = webSongs.skip(15).take(10).toList();
        _error = null;
        notifyListeners();
      } else {
        throw Exception('Failed to load from iTunes API');
      }
    } catch (e) {
      AppLogger.error('iTunes API Error: $e');
      _error = 'Failed to load music from web';
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
