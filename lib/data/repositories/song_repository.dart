import '../../models/song_model.dart';

/// Abstract contract for song data access.
///
/// Providers depend on this interface, never on FirebaseService or
/// any specific backend implementation directly. This enables:
///   - Easy backend swap (Firebase → Supabase → REST, etc.)
///   - Straightforward unit testing with mock implementations
///   - Clear separation of concerns: data vs. business logic vs. UI
abstract class SongRepository {
  /// Fetch songs ordered by upload date, newest first.
  /// [limit] — maximum number of songs to return.
  /// [afterId] — optional cursor for pagination (song ID to start after).
  Future<List<Song>> getSongs({int limit = 50, String? afterId});

  /// Fetch the most-played songs, ordered by play count descending.
  Future<List<Song>> getPopularSongs({int limit = 20});

  /// Real-time stream that emits the full songs collection on any change.
  /// Used by the home feed to show newly uploaded songs instantly.
  Stream<List<Song>> watchSongs({int limit = 100});

  /// Fetch a single song by its ID.
  Future<Song> getSongById(String id);

  /// Prefix-match search on song title (case-insensitive where possible).
  /// Note: Firestore supports only prefix matches. For full-text search, consider Algolia.
  Future<List<Song>> searchByTitle(String query, {int limit = 20});

  /// Persist a new song document to the backend.
  /// The [song] must already have a valid, unique [id].
  Future<void> addSong(Song song);

  /// Update an existing song document. Only non-null fields are changed.
  Future<void> updateSong(Song song);

  /// Permanently remove a song by [id].
  Future<void> deleteSong(String id);

  /// Atomically increment the play count for [songId].
  /// This is a best-effort operation — failures are logged, not rethrown.
  Future<void> incrementPlayCount(String songId);
}
