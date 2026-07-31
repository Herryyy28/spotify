import 'dart:async';
import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../data/repositories/song_repository.dart';
import '../data/repositories/firestore_song_repository.dart';

class HomeProvider extends ChangeNotifier {
  final SongRepository _songRepository;

  HomeProvider({SongRepository? songRepository})
      : _songRepository = songRepository ?? FirestoreSongRepository();

  List<Song> _featuredSongs = [];
  final List<Song> _recentSongs = [];
  List<Song> _popularSongs = [];
  List<Song> _newHits = [];
  List<Playlist> _featuredPlaylists = [];
  List<Playlist> _recommendedPlaylists = [];
  List<Playlist> _charts = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Song>>? _songsSubscription;

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
      // Subscribe to real-time updates — newly uploaded songs appear instantly
      _songsSubscription?.cancel();
      _songsSubscription = _songRepository.watchSongs(limit: 100).listen(
        (firebaseSongs) {
          if (firebaseSongs.isNotEmpty) {
            _featuredSongs =
                _mergeSongs(firebaseSongs, _featuredSongs).take(10).toList();
            _popularSongs =
                _mergeSongs(firebaseSongs, _popularSongs).take(15).toList();
            _newHits = _mergeSongs(firebaseSongs, _newHits);
            _buildPlaylistsFromSongs(
                [..._featuredSongs, ..._popularSongs, ..._newHits]);
            _error = null;
            notifyListeners();
          }
        },
        onError: (e) => AppLogger.error('Song stream error: $e'),
      );

      // Fetch initial snapshot in parallel (faster than waiting for stream)
      final results = await Future.wait([
        _songRepository.getSongs(limit: 10),
        _songRepository.getPopularSongs(limit: 10),
        _songRepository.getSongs(limit: 10),
      ]);

      _featuredSongs = _mergeSongs(results[0], _featuredSongs);
      _popularSongs = _mergeSongs(results[1], _popularSongs);
      _newHits = _mergeSongs(results[2], _newHits);

      // If Firebase is empty, populate with initial demo songs
      if (_featuredSongs.isEmpty && _popularSongs.isEmpty && _newHits.isEmpty) {
        await _loadWebFallbackSongs();
      } else {
        _buildPlaylistsFromSongs(
            [..._featuredSongs, ..._popularSongs, ..._newHits]);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error loading music data: $e');
      await _loadWebFallbackSongs();
    } finally {
      _setLoading(false);
    }
  }

  List<Song> _mergeSongs(List<Song> priorityList, List<Song> secondaryList) {
    final Map<String, Song> merged = {};
    for (final song in priorityList) {
      merged[song.id] = song;
    }
    for (final song in secondaryList) {
      if (!merged.containsKey(song.id)) {
        merged[song.id] = song;
      }
    }
    return merged.values.toList();
  }

  Future<void> _loadWebFallbackSongs() async {
    final mockOfflineSongs = [
      Song(
        id: 'offline_1',
        title: 'Sunset Lofi Horizon',
        artist: 'Ambient Soundscape',
        album: 'Cozy Afternoons',
        duration: '3:02',
        durationInSeconds: 182,
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        coverUrl:
            'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=500&q=80',
        releaseDate: DateTime.now(),
      ),
      Song(
        id: 'offline_2',
        title: 'Neon Midnight Cruise',
        artist: 'Retro Horizon',
        album: 'Outrun Drive',
        duration: '4:15',
        durationInSeconds: 255,
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        coverUrl:
            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80',
        releaseDate: DateTime.now(),
      ),
      Song(
        id: 'offline_3',
        title: 'Raindrops & Cafe Ambient',
        artist: 'Acoustic Solitude',
        album: 'Coffee Shop Study',
        duration: '2:50',
        durationInSeconds: 170,
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        coverUrl:
            'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=500&q=80',
        releaseDate: DateTime.now(),
      ),
    ];

    _featuredSongs = _mergeSongs(_featuredSongs, mockOfflineSongs);
    _popularSongs = _mergeSongs(_popularSongs, mockOfflineSongs);
    _newHits = _mergeSongs(_newHits, mockOfflineSongs);

    _buildPlaylistsFromSongs(
        [..._featuredSongs, ..._popularSongs, ..._newHits]);
    _error = null;
    notifyListeners();
  }

  void _buildPlaylistsFromSongs(List<Song> songs) {
    if (songs.isEmpty) return;

    final topSongs = songs.take(8).toList();
    final chillSongs = songs.skip(3).take(8).toList();
    final workoutSongs = songs.skip(6).take(8).toList();
    final chartSongs = songs.skip(9).take(8).toList();

    _featuredPlaylists = [
      Playlist(
        id: 'pl_global_top_50',
        name: 'Global Top 50',
        description: 'The hottest tracks trending right now worldwide',
        coverUrl: topSongs.isNotEmpty ? topSongs.first.coverUrl : null,
        userId: 'system',
        userName: 'Harmony Editors',
        songs: topSongs,
        songCount: topSongs.length,
        totalDuration: topSongs.fold(0, (sum, s) => sum + s.durationInSeconds),
        followersCount: 254900,
        isPublic: true,
        isCollaborative: false,
        collaborators: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['Top 50', 'Global', 'Pop'],
      ),
      Playlist(
        id: 'pl_chill_vibes',
        name: 'Chill & Relax Vibes',
        description: 'Smooth melodies to unwind and relax',
        coverUrl: chillSongs.isNotEmpty ? chillSongs.first.coverUrl : null,
        userId: 'system',
        userName: 'Harmony Editors',
        songs: chillSongs,
        songCount: chillSongs.length,
        totalDuration:
            chillSongs.fold(0, (sum, s) => sum + s.durationInSeconds),
        followersCount: 184200,
        isPublic: true,
        isCollaborative: false,
        collaborators: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['Chill', 'Acoustic'],
      ),
    ];

    _recommendedPlaylists = [
      Playlist(
        id: 'pl_workout_energy',
        name: 'Workout Motivation',
        description: 'High energy beats to power through your fitness session',
        coverUrl: workoutSongs.isNotEmpty ? workoutSongs.first.coverUrl : null,
        userId: 'system',
        userName: 'Harmony Fitness',
        songs: workoutSongs,
        songCount: workoutSongs.length,
        totalDuration:
            workoutSongs.fold(0, (sum, s) => sum + s.durationInSeconds),
        followersCount: 94300,
        isPublic: true,
        isCollaborative: false,
        collaborators: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['Workout', 'EDM', 'Pop'],
      ),
    ];

    _charts = [
      Playlist(
        id: 'chart_weekly_top_100',
        name: 'Weekly Top Charts',
        description: 'Most streamed tracks of this week',
        coverUrl: chartSongs.isNotEmpty ? chartSongs.first.coverUrl : null,
        userId: 'system',
        userName: 'Harmony Charts',
        songs: chartSongs,
        songCount: chartSongs.length,
        totalDuration:
            chartSongs.fold(0, (sum, s) => sum + s.durationInSeconds),
        followersCount: 521000,
        isPublic: true,
        isCollaborative: false,
        collaborators: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: ['Charts', 'Trending'],
      ),
    ];
  }

  List<Song> get allSongs {
    final Map<String, Song> uniqueSongs = {};
    for (var song in [
      ..._featuredSongs,
      ..._popularSongs,
      ..._newHits,
      ..._recentSongs
    ]) {
      uniqueSongs[song.id] = song;
    }
    return uniqueSongs.values.toList();
  }

  /// Adds a song to the local in-memory state and notifies listeners.
  /// Callers are responsible for persisting the song to Firebase before calling this.
  void addSong(Song song) {
    // Avoid duplicates if the stream listener fires shortly after
    if (_featuredSongs.any((s) => s.id == song.id) ||
        _newHits.any((s) => s.id == song.id)) {
      return;
    }
    _newHits.insert(0, song);
    _featuredSongs.insert(0, song);
    notifyListeners();
  }

  /// Updates a song in local in-memory state and notifies listeners.
  /// Callers are responsible for persisting the update to Firebase.
  void updateSong(Song updatedSong) {
    void updateInList(List<Song> list) {
      final index = list.indexWhere((s) => s.id == updatedSong.id);
      if (index != -1) list[index] = updatedSong;
    }

    updateInList(_featuredSongs);
    updateInList(_popularSongs);
    updateInList(_newHits);
    updateInList(_recentSongs);
    notifyListeners();
  }

  /// Deletes a song from local in-memory state and notifies listeners.
  /// Callers are responsible for deleting from Firebase.
  void deleteSong(String songId) {
    _featuredSongs.removeWhere((s) => s.id == songId);
    _popularSongs.removeWhere((s) => s.id == songId);
    _newHits.removeWhere((s) => s.id == songId);
    _recentSongs.removeWhere((s) => s.id == songId);
    notifyListeners();
  }

  /// Replaces the current song lists with a new collection of songs.
  void setSongs(List<Song> songs) {
    if (songs.isEmpty) return;

    _featuredSongs = songs.take(5).toList();
    _popularSongs = songs.skip(5).take(10).toList();
    if (_popularSongs.isEmpty) _popularSongs = List.from(songs);
    _newHits = songs.skip(15).take(10).toList();
    if (_newHits.isEmpty) _newHits = List.from(songs);

    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _songsSubscription?.cancel();
    super.dispose();
  }
}
