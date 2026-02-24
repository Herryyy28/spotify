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
        _firebaseService.getSongs(
            limit: 10), // New Hits (for now, using recent songs)
      ]);

      _featuredSongs = results[0];
      _popularSongs = results[1];
      _newHits = results[2];

      // For playlists, we'll use empty lists for now
      // TODO: Add Firebase methods to get featured/recommended playlists and charts
      _featuredPlaylists = [];
      _recommendedPlaylists = [];
      _charts = [];

      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading music data: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
