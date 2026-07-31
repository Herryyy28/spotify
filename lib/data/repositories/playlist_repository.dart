import '../../models/playlist_model.dart';

/// Abstract contract for playlist data access.
abstract class PlaylistRepository {
  /// Fetches a user's custom playlists.
  Future<List<Playlist>> getUserPlaylists(String userId);

  /// Fetches all admin-curated/featured playlists.
  Future<List<Playlist>> getFeaturedPlaylists({int limit = 10});

  /// Fetches recommended playlists.
  Future<List<Playlist>> getRecommendedPlaylists({int limit = 10});
  
  /// Fetches chart playlists (e.g. Top 50).
  Future<List<Playlist>> getChartPlaylists({int limit = 10});

  /// Gets a specific playlist by ID.
  Future<Playlist?> getPlaylistById(String id);

  /// Creates a new playlist.
  Future<Playlist> createPlaylist(Playlist playlist);

  /// Updates an existing playlist.
  Future<void> updatePlaylist(Playlist playlist);

  /// Deletes a playlist.
  Future<void> deletePlaylist(String playlistId);

  /// Adds a song to a playlist.
  Future<void> addSongToPlaylist(String playlistId, String songId);

  /// Removes a song from a playlist.
  Future<void> removeSongFromPlaylist(String playlistId, String songId);
}
