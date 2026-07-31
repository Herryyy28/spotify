import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/logger.dart';
import 'user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _db;

  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'users';

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      AppLogger.error('FirestoreUserRepository.getUserProfile failed: $e');
    }
    return null;
  }

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(userId).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      AppLogger.error('FirestoreUserRepository.updateUserProfile failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> addToRecentlyPlayed(String userId, String songId) async {
    try {
      await _db.collection(_collection).doc(userId).collection('history').add({
        'songId': songId,
        'playedAt': FieldValue.serverTimestamp(),
      });
      // Optionally maintain a fast-access array in the main user doc for the last 50 songs
      await _db.collection(_collection).doc(userId).set({
        'recentSongs': FieldValue.arrayUnion([songId]),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.warning('FirestoreUserRepository.addToRecentlyPlayed failed: $e');
    }
  }

  @override
  Future<void> toggleLikedSong(String userId, String songId) async {
    try {
      final docRef = _db.collection(_collection).doc(userId).collection('likes').doc(songId);
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'songId': songId,
          'likedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      AppLogger.error('FirestoreUserRepository.toggleLikedSong failed: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getLikedSongIds(String userId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .doc(userId)
          .collection('likes')
          .orderBy('likedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      AppLogger.error('FirestoreUserRepository.getLikedSongIds failed: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentlyPlayed(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .doc(userId)
          .collection('history')
          .orderBy('playedAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      AppLogger.error('FirestoreUserRepository.getRecentlyPlayed failed: $e');
      return [];
    }
  }
  
  @override
  Future<void> logListeningEvent(String userId, String songId, int durationSec) async {
    try {
      await _db.collection(_collection).doc(userId).collection('listening_events').add({
        'songId': songId,
        'durationSec': durationSec,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.warning('FirestoreUserRepository.logListeningEvent failed: $e');
    }
  }
}
