import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/podcast_model.dart';

class PodcastProvider extends ChangeNotifier {
  List<Podcast> _podcasts = [];
  Podcast? _selectedPodcast;
  Episode? _currentEpisode;
  Map<String, int> _episodeProgress = {}; // episodeId -> seconds listened
  List<String> _bookmarkedEpisodes = [];
  List<String> _subscribedPodcasts = [];
  bool _isLoading = false;

  List<Podcast> get podcasts => _podcasts;
  Podcast? get selectedPodcast => _selectedPodcast;
  Episode? get currentEpisode => _currentEpisode;
  Map<String, int> get episodeProgress => _episodeProgress;
  List<String> get bookmarkedEpisodes => _bookmarkedEpisodes;
  List<String> get subscribedPodcasts => _subscribedPodcasts;
  bool get isLoading => _isLoading;

  PodcastProvider() {
    _loadPreferences();
    _loadSamplePodcasts();
  }

  void _loadSamplePodcasts() {
    // Sample data — in production this comes from an RSS/API service
    final now = DateTime.now();
    _podcasts = [
      Podcast(
        id: 'p1',
        title: 'The Music Universe',
        publisher: 'Harmony Studios',
        description: 'Exploring the world of music, from classical to EDM.',
        categories: ['Music', 'Culture'],
        subscribers: 12400,
        episodeCount: 3,
        lastUpdated: now.subtract(const Duration(days: 2)),
        averageRating: 4.8,
        totalRatings: 1200,
        episodes: [
          Episode(
            id: 'e1',
            title: 'The History of Jazz',
            description: 'A deep dive into the origins and evolution of jazz music.',
            audioUrl: 'https://example.com/episode1.mp3',
            duration: 3600,
            publishDate: now.subtract(const Duration(days: 2)),
          ),
          Episode(
            id: 'e2',
            title: 'Electronic Music Revolution',
            description: 'How electronic music changed the world.',
            audioUrl: 'https://example.com/episode2.mp3',
            duration: 2700,
            publishDate: now.subtract(const Duration(days: 9)),
          ),
          Episode(
            id: 'e3',
            title: 'The Art of Songwriting',
            description: 'Interview with top songwriters.',
            audioUrl: 'https://example.com/episode3.mp3',
            duration: 4200,
            publishDate: now.subtract(const Duration(days: 16)),
          ),
        ],
      ),
      Podcast(
        id: 'p2',
        title: 'Sound Waves',
        publisher: 'AudioCraft',
        description: 'Weekly podcast about music production and audio engineering.',
        categories: ['Music', 'Technology'],
        subscribers: 8600,
        episodeCount: 2,
        lastUpdated: now.subtract(const Duration(days: 1)),
        averageRating: 4.6,
        totalRatings: 890,
        episodes: [
          Episode(
            id: 'e4',
            title: 'Mixing for Streaming',
            description: 'How to optimize your mixes for streaming platforms.',
            audioUrl: 'https://example.com/episode4.mp3',
            duration: 2400,
            publishDate: now.subtract(const Duration(days: 1)),
          ),
          Episode(
            id: 'e5',
            title: 'Mastering Fundamentals',
            description: 'Everything you need to know about audio mastering.',
            audioUrl: 'https://example.com/episode5.mp3',
            duration: 3000,
            publishDate: now.subtract(const Duration(days: 8)),
          ),
        ],
      ),
      Podcast(
        id: 'p3',
        title: 'Artist Stories',
        publisher: 'Harmony Music',
        description: 'In-depth interviews with your favorite artists.',
        categories: ['Interviews', 'Music'],
        subscribers: 24000,
        episodeCount: 2,
        lastUpdated: now.subtract(const Duration(hours: 5)),
        averageRating: 4.9,
        totalRatings: 3100,
        episodes: [
          Episode(
            id: 'e6',
            title: 'A Conversation with the Stars',
            description: 'Exclusive interviews from the top artists of the year.',
            audioUrl: 'https://example.com/episode6.mp3',
            duration: 5400,
            publishDate: now.subtract(const Duration(hours: 5)),
          ),
          Episode(
            id: 'e7',
            title: 'Behind the Album',
            description: 'Artists share the stories behind their latest records.',
            audioUrl: 'https://example.com/episode7.mp3',
            duration: 4800,
            publishDate: now.subtract(const Duration(days: 7)),
          ),
        ],
      ),
    ];
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarkedEpisodes = prefs.getStringList('bookmarked_episodes') ?? [];
    _subscribedPodcasts = prefs.getStringList('subscribed_podcasts') ?? [];
    final progressJson = prefs.getString('episode_progress');
    if (progressJson != null) {
      final decoded = json.decode(progressJson) as Map<String, dynamic>;
      _episodeProgress = decoded.map((k, v) => MapEntry(k, v as int));
    }
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarked_episodes', _bookmarkedEpisodes);
    await prefs.setStringList('subscribed_podcasts', _subscribedPodcasts);
    await prefs.setString('episode_progress', json.encode(_episodeProgress));
  }

  void selectPodcast(Podcast podcast) {
    _selectedPodcast = podcast;
    notifyListeners();
  }

  void playEpisode(Episode episode) {
    _currentEpisode = episode;
    notifyListeners();
    AppLogger.info('Playing episode: ${episode.title}');
  }

  void toggleBookmark(String episodeId) {
    if (_bookmarkedEpisodes.contains(episodeId)) {
      _bookmarkedEpisodes.remove(episodeId);
    } else {
      _bookmarkedEpisodes.add(episodeId);
    }
    _savePreferences();
    notifyListeners();
  }

  bool isBookmarked(String episodeId) => _bookmarkedEpisodes.contains(episodeId);

  void toggleSubscribe(String podcastId) {
    if (_subscribedPodcasts.contains(podcastId)) {
      _subscribedPodcasts.remove(podcastId);
    } else {
      _subscribedPodcasts.add(podcastId);
    }
    _savePreferences();
    notifyListeners();
  }

  bool isSubscribed(String podcastId) => _subscribedPodcasts.contains(podcastId);

  void updateProgress(String episodeId, int seconds) {
    _episodeProgress[episodeId] = seconds;
    _savePreferences();
  }

  double getProgressFraction(Episode episode) {
    final listened = _episodeProgress[episode.id] ?? 0;
    if (episode.duration == 0) return 0;
    return listened / episode.duration;
  }
}
