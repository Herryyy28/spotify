import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../services/ai_recommendation_service.dart';

/// Provider for AI-powered recommendations
class RecommendationProvider extends ChangeNotifier {
  final AIRecommendationService _aiService = AIRecommendationService();

  List<Song> _personalizedRecommendations = [];
  List<Song> _discoverWeekly = [];
  List<Playlist> _dailyMixes = [];
  List<Song> _moodRecommendations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Song> get personalizedRecommendations => _personalizedRecommendations;
  List<Song> get discoverWeekly => _discoverWeekly;
  List<Playlist> get dailyMixes => _dailyMixes;
  List<Song> get moodRecommendations => _moodRecommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all recommendations for a user
  Future<void> loadRecommendations(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load recommendations in parallel
      final results = await Future.wait([
        _aiService.getPersonalizedRecommendations(userId, limit: 20),
        _aiService.getDiscoverWeekly(userId, limit: 30),
        _aiService.getDailyMixes(userId, mixCount: 6),
        _aiService.getTimeBasedRecommendations(limit: 15),
      ]);

      _personalizedRecommendations = results[0] as List<Song>;
      _discoverWeekly = results[1] as List<Song>;
      _dailyMixes = results[2] as List<Playlist>;
      _moodRecommendations = results[3] as List<Song>;

      _error = null;
    } catch (e) {
      _error = 'Failed to load recommendations: $e';
      AppLogger.error(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get recommendations based on mood
  Future<List<Song>> getRecommendationsByMood(String mood) async {
    try {
      final songs = await _aiService.getRecommendationsByMood(mood, limit: 20);
      _moodRecommendations = songs;
      notifyListeners();
      return songs;
    } catch (e) {
      AppLogger.error('Error getting mood recommendations: $e');
      return [];
    }
  }

  /// Get similar songs
  Future<List<Song>> getSimilarSongs(Song song) async {
    try {
      return await _aiService.getSimilarSongs(song, limit: 10);
    } catch (e) {
      AppLogger.error('Error getting similar songs: $e');
      return [];
    }
  }

  /// Generate a smart playlist
  Future<Playlist?> generateSmartPlaylist(String theme, String userId) async {
    try {
      return await _aiService.generateSmartPlaylist(theme, userId,
          songCount: 30);
    } catch (e) {
      AppLogger.error('Error generating smart playlist: $e');
      return null;
    }
  }

  /// Refresh recommendations
  Future<void> refresh(String userId) async {
    await loadRecommendations(userId);
  }
}
