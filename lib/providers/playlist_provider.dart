import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/firebase_service.dart';
import '../services/download_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final DownloadService _downloadService = DownloadService();

  List<Playlist> _playlists = [];
  Playlist? _currentPlaylist;
  bool _isLoading = false;
  String? _error;

  List<Playlist> get playlists => _playlists;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor
  PlaylistProvider() {
    loadPlaylists();
  }

  // Load user playlists
  Future<void> loadPlaylists([dynamic userId]) async {
    _setLoading(true);
    try {
      final currentUserId = userId ?? _firebaseService.userId;
      if (currentUserId != null) {
        _playlists = await _firebaseService.getUserPlaylists(currentUserId);
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
      _currentPlaylist = await _firebaseService.getPlaylist(id);
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

      final created = await _firebaseService.createPlaylist(playlist);
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
      // Implement update in Firebase
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
      await _firebaseService.deletePlaylist(id);
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
      await _firebaseService.addSongToPlaylist(playlistId, song.id);

      // Update local playlist if it's the current one
      if (_currentPlaylist?.id == playlistId) {
        _currentPlaylist!.songs.add(song);
        _currentPlaylist!.songCount += 1;
        _currentPlaylist!.totalDuration += song.durationInSeconds;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Remove song from playlist
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _firebaseService.removeSongFromPlaylist(playlistId, songId);

      // Update local playlist if it's the current one
      if (_currentPlaylist?.id == playlistId) {
        final songIndex =
            _currentPlaylist!.songs.indexWhere((s) => s.id == songId);
        if (songIndex != -1) {
          final song = _currentPlaylist!.songs[songIndex];
          _currentPlaylist!.songs.removeAt(songIndex);
          _currentPlaylist!.songCount -= 1;
          _currentPlaylist!.totalDuration -= song.durationInSeconds;
          notifyListeners();
        }
      }

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
      final playlist = await _firebaseService.getPlaylist(playlistId);
      await _downloadService.downloadPlaylist(playlist.songs);
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
