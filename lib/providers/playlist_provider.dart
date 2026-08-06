import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/utils/logger.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../data/repositories/playlist_repository.dart';
import '../data/repositories/firestore_playlist_repository.dart';
import '../services/download_service.dart';
import '../services/firebase_service.dart'; // Keep for user ID fallback for now

class PlaylistProvider extends ChangeNotifier {
  final PlaylistRepository _playlistRepository;
  final DownloadService _downloadService = DownloadService();
  final FirebaseService _firebaseService = FirebaseService();

  List<Playlist> _playlists = [];
  Playlist? _currentPlaylist;
  bool _isLoading = false;
  String? _error;

  List<Playlist> get playlists => _playlists;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor
  PlaylistProvider({PlaylistRepository? playlistRepository})
      : _playlistRepository = playlistRepository ?? FirestorePlaylistRepository() {
    loadPlaylists();
  }

  // Load user playlists
  Future<void> loadPlaylists([dynamic userId]) async {
    _setLoading(true);
    try {
      final currentUserId = userId ?? _firebaseService.userId;
      if (currentUserId != null) {
        // Try loading from cache first
        try {
          final box = Hive.box('user_cache');
          final cachedPlaylists = box.get('playlists_$currentUserId');
          if (cachedPlaylists != null) {
            final List<dynamic> decodedList = jsonDecode(cachedPlaylists);
            _playlists = decodedList.map((p) => Playlist.fromJson(p)).toList();
            // Don't set loading to false yet, show cached data but keep refreshing
            notifyListeners(); 
          }
        } catch (e) {
          AppLogger.error('Cache read error: $e');
        }

        // Fetch fresh from remote
        _playlists = await _playlistRepository.getUserPlaylists(currentUserId);
        
        // Update cache silently
        try {
          final box = Hive.box('user_cache');
          final encodedList = jsonEncode(_playlists.map((p) => p.toJson()).toList());
          box.put('playlists_$currentUserId', encodedList);
        } catch (e) {
          AppLogger.error('Cache write error: $e');
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Get playlist by id
  Future<void> getPlaylist(String id) async {
    _setLoading(true);
    try {
      _currentPlaylist = await _playlistRepository.getPlaylistById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Create playlist
  Future<bool> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
    bool isPublic = true,
  }) async {
    _setLoading(true);
    try {
      final userId = _firebaseService.userId;
      final userName = _firebaseService.displayName ?? 'User';

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final playlist = Playlist(
        id: '', // Will be assigned by Firebase
        name: name,
        description: description,
        coverUrl: coverUrl,
        userId: userId,
        userName: userName,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _playlistRepository.createPlaylist(playlist);
      _playlists.insert(0, created);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update playlist
  Future<bool> updatePlaylist(Playlist playlist) async {
    _setLoading(true);
    try {
      await _playlistRepository.updatePlaylist(playlist);
      
      // Update in local lists if present
      final index = _playlists.indexWhere((p) => p.id == playlist.id);
      if (index != -1) {
        _playlists[index] = playlist;
      }
      if (_currentPlaylist?.id == playlist.id) {
        _currentPlaylist = playlist;
      }
      
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }


  // Delete playlist
  Future<bool> deletePlaylist(String id) async {
    _setLoading(true);
    try {
      await _playlistRepository.deletePlaylist(id);
      _playlists.removeWhere((p) => p.id == id);
      if (_currentPlaylist?.id == id) {
        _currentPlaylist = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add song to playlist
  Future<bool> addSongToPlaylist(String playlistId, Song song) async {
    try {
      Playlist? targetPlaylist;
      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        if (!_playlists[index].songs.any((s) => s.id == song.id)) {
          _playlists[index].songs.add(song);
          _playlists[index].songCount += 1;
          _playlists[index].totalDuration += song.durationInSeconds;
          targetPlaylist = _playlists[index];
        }
      }

      // Update local playlist if it's the current one
      if (_currentPlaylist?.id == playlistId) {
        if (!_currentPlaylist!.songs.any((s) => s.id == song.id)) {
          _currentPlaylist!.songs.add(song);
          _currentPlaylist!.songCount += 1;
          _currentPlaylist!.totalDuration += song.durationInSeconds;
          targetPlaylist = _currentPlaylist;
        }
      }
      
      if (targetPlaylist != null) {
        await _playlistRepository.updatePlaylist(targetPlaylist);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Remove song from playlist
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      Playlist? targetPlaylist;
      // Update in _playlists list
      final listIndex = _playlists.indexWhere((p) => p.id == playlistId);
      if (listIndex != -1) {
        final songIndex = _playlists[listIndex].songs.indexWhere((s) => s.id == songId);
        if (songIndex != -1) {
          final song = _playlists[listIndex].songs[songIndex];
          _playlists[listIndex].songs.removeAt(songIndex);
          _playlists[listIndex].songCount -= 1;
          _playlists[listIndex].totalDuration -= song.durationInSeconds;
          targetPlaylist = _playlists[listIndex];
        }
      }

      // Update local playlist if it's the current one
      if (_currentPlaylist?.id == playlistId) {
        final songIndex =
            _currentPlaylist!.songs.indexWhere((s) => s.id == songId);
        if (songIndex != -1) {
          final song = _currentPlaylist!.songs[songIndex];
          _currentPlaylist!.songs.removeAt(songIndex);
          _currentPlaylist!.songCount -= 1;
          _currentPlaylist!.totalDuration -= song.durationInSeconds;
          targetPlaylist = _currentPlaylist;
        }
      }
      
      if (targetPlaylist != null) {
        await _playlistRepository.updatePlaylist(targetPlaylist);
      }
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Reorder playlist
  void reorderPlaylist(int oldIndex, int newIndex) {
    if (_currentPlaylist != null) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final song = _currentPlaylist!.songs.removeAt(oldIndex);
      _currentPlaylist!.songs.insert(newIndex, song);
      _currentPlaylist!.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  // Clear current playlist
  void clearCurrentPlaylist() {
    _currentPlaylist = null;
    notifyListeners();
  }

  // Download playlist
  Future<void> downloadPlaylist(String playlistId) async {
    try {
      final playlist = await _playlistRepository.getPlaylistById(playlistId);
      if (playlist != null) {
        await _downloadService.downloadPlaylist(playlist.songs);
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  // Search playlists
  Future<List<Playlist>> searchPlaylists(String query) async {
    try {
      // Implement search in Firebase
      return [];
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Follow playlist
  Future<void> followPlaylist(String playlistId) async {
    try {
      // Implement follow functionality
    } catch (e) {
      _error = e.toString();
    }
  }

  // Unfollow playlist
  Future<void> unfollowPlaylist(String playlistId) async {
    try {
      // Implement unfollow functionality
    } catch (e) {
      _error = e.toString();
    }
  }

  // Get playlist stats
  Map<String, dynamic> getPlaylistStats(Playlist playlist) {
    final totalDuration = Duration(seconds: playlist.totalDuration);
    final averageDuration = playlist.songs.isEmpty
        ? Duration.zero
        : Duration(seconds: playlist.totalDuration ~/ playlist.songs.length);

    final artists = playlist.songs.map((s) => s.artist).toSet().length;
    final albums = playlist.songs.map((s) => s.album).toSet().length;

    return {
      'totalSongs': playlist.songCount,
      'totalDuration': totalDuration,
      'averageDuration': averageDuration,
      'uniqueArtists': artists,
      'uniqueAlbums': albums,
      'createdAt': playlist.createdAt,
      'updatedAt': playlist.updatedAt,
    };
  }

  // Error handling
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
