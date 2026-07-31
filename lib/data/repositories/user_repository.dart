import '../../models/user_model.dart'; // We may need to create this if it doesn't exist, or use Map<String, dynamic>

abstract class UserRepository {
  /// Fetches a user's profile by ID.
  Future<Map<String, dynamic>?> getUserProfile(String userId);

  /// Updates a user's profile.
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data);

  /// Records a recently played song for a user.
  Future<void> addToRecentlyPlayed(String userId, String songId);
  
  /// Gets a user's recently played songs history.
  Future<List<Map<String, dynamic>>> getRecentlyPlayed(String userId, {int limit = 20});
  
  /// Logs a listening event (with duration) for analytics/history.
  Future<void> logListeningEvent(String userId, String songId, int durationSec);
  
  /// Toggles like/unlike for a song.
  Future<void> toggleLikedSong(String userId, String songId);
  
  /// Gets the user's liked songs.
  Future<List<String>> getLikedSongIds(String userId);
}
