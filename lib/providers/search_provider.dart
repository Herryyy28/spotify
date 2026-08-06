import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';
import '../data/repositories/song_repository.dart';
import '../data/repositories/firestore_song_repository.dart';

import '../core/utils/logger.dart';

class SearchProvider extends ChangeNotifier {
  final SongRepository _songRepository;

  SearchProvider({SongRepository? songRepository})
      : _songRepository = songRepository ?? FirestoreSongRepository() {
    _loadRecentSearches();
  }

  List<Song> _songResults = [];
  List<Artist> _artistResults = [];
  List<Playlist> _playlistResults = [];
  List<String> _recentSearches = [];

  bool _isSearching = false;
  bool _isLoading = false;
  String _selectedFilter = 'All';

  List<Song> get songResults => _songResults;
  List<Artist> get artistResults => _artistResults;
  List<Playlist> get playlistResults => _playlistResults;
  List<String> get recentSearches => _recentSearches;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> _loadRecentSearches() async {
    // In the future, this can be loaded from SharedPreferences/Hive
    _recentSearches = [
      'Imagine Dragons',
      'Ed Sheeran',
      'Pop Hits',
      'Workout'
    ];
    notifyListeners();
  }

  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
      notifyListeners();
      // TODO: Save to SharedPreferences/Hive
    }
  }

  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    notifyListeners();
    // TODO: Save to SharedPreferences/Hive
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
    // TODO: Save to SharedPreferences/Hive
  }

  void clearSearch() {
    _songResults = [];
    _artistResults = [];
    _playlistResults = [];
    _isSearching = false;
    _isLoading = false;
    notifyListeners();
  }

  Timer? _debounceTimer;

  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      clearSearch();
      return;
    }

    _isSearching = true;
    _isLoading = true;
    notifyListeners();

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _songRepository.searchByTitle(query);

        // Combine unique songs by ID
        final Map<String, Song> uniqueResults = {};
        for (var song in results) {
          uniqueResults[song.id] = song;
        }

        _songResults = uniqueResults.values.toList();
        _isLoading = false;
        
        if (query.length > 2) {
          addRecentSearch(query);
        }
        
        notifyListeners();
      } catch (e) {
        AppLogger.error('Search failed: $e');
        _isLoading = false;
        notifyListeners();
      }
    });
  }
}
