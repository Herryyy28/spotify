import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/analytics_service.dart';

/// Provider for user analytics and statistics
class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  UserStats? _userStats;
  ListeningPatterns? _listeningPatterns;
  YearInReview? _yearInReview;
  List<Song> _topSongs = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UserStats? get userStats => _userStats;
  ListeningPatterns? get listeningPatterns => _listeningPatterns;
  YearInReview? get yearInReview => _yearInReview;
  List<Song> get topSongs => _topSongs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Track a song play
  Future<void> trackSongPlay(String userId, Song song) async {
    try {
      await _analyticsService.trackSongPlay(userId, song);
    } catch (e) {
      AppLogger.error('Error tracking song play: $e');
    }
  }

  /// Load user statistics
  Future<void> loadUserStatistics(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _analyticsService.getUserStatistics(userId),
        _analyticsService.getListeningPatterns(userId),
        _analyticsService.getTopSongs(userId, limit: 50),
      ]);

      _userStats = results[0] as UserStats;
      _listeningPatterns = results[1] as ListeningPatterns;
      _topSongs = results[2] as List<Song>;

      _error = null;
    } catch (e) {
      _error = 'Failed to load statistics: $e';
      AppLogger.error(_error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load year in review
  Future<void> loadYearInReview(String userId, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _yearInReview = await _analyticsService.getYearInReview(userId, year);
      _error = null;
    } catch (e) {
      _error = 'Failed to load year in review: $e';
      AppLogger.error(_error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh statistics
  Future<void> refresh(String userId) async {
    await loadUserStatistics(userId);
  }
}
