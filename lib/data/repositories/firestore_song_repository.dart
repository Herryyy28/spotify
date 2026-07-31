import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/logger.dart';
import '../../models/song_model.dart';
import 'song_repository.dart';

/// Firestore implementation of [SongRepository].
///
/// All Firestore-specific knowledge is isolated here. No other file in the
/// project should import cloud_firestore for song operations.
class FirestoreSongRepository implements SongRepository {
  final FirebaseFirestore _db;

  FirestoreSongRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'songs';

  // ── Read operations ────────────────────────────────────────────────────────

  @override
  Future<List<Song>> getSongs({int limit = 50, String? afterId}) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (afterId != null) {
        final cursor = await _db.collection(_collection).doc(afterId).get();
        if (cursor.exists) {
          query = query.startAfterDocument(cursor);
        }
      }

      final snapshot = await query.get();
      return _mapDocs(snapshot.docs);
    } catch (e) {
      AppLogger.error('FirestoreSongRepository.getSongs failed: $e');
      // Return empty list — caller decides how to handle empty state
      return [];
    }
  }

  @override
  Future<List<Song>> getPopularSongs({int limit = 20}) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .orderBy('playCount', descending: true)
          .limit(limit)
          .get();
      return _mapDocs(snapshot.docs);
    } catch (e) {
      AppLogger.error('FirestoreSongRepository.getPopularSongs failed: $e');
      return [];
    }
  }

  @override
  Stream<List<Song>> watchSongs({int limit = 100}) {
    return _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => _mapDocs(snapshot.docs))
        // Catch per-event errors so the stream does not terminate on transient failures
        .handleError((Object e) {
          AppLogger.error('FirestoreSongRepository.watchSongs stream error: $e');
          return <Song>[];
        });
  }

  @override
  Future<Song> getSongById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) {
      throw StateError('Song $id not found in Firestore');
    }
    final data = doc.data()!;
    data['id'] = doc.id;
    return Song.fromJson(data);
  }

  @override
  Future<List<Song>> searchByTitle(String query, {int limit = 20}) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}\uf8ff')
          .limit(limit)
          .get();
      return _mapDocs(snapshot.docs);
    } catch (e) {
      AppLogger.error('FirestoreSongRepository.searchByTitle failed: $e');
      return [];
    }
  }

  // ── Write operations ───────────────────────────────────────────────────────

  @override
  Future<void> addSong(Song song) async {
    await _db.collection(_collection).doc(song.id).set({
      ...song.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateSong(Song song) async {
    final data = song.toJson()
      ..remove('createdAt'); // Preserve original creation timestamp
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(_collection).doc(song.id).update(data);
  }

  @override
  Future<void> deleteSong(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  @override
  Future<void> incrementPlayCount(String songId) async {
    try {
      await _db.collection(_collection).doc(songId).update({
        'playCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Non-critical — do not propagate
      AppLogger.warning('FirestoreSongRepository.incrementPlayCount failed: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Song> _mapDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final songs = <Song>[];
    for (final doc in docs) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        songs.add(Song.fromJson(data));
      } catch (e) {
        // Skip malformed documents — log and continue instead of crashing the entire list
        AppLogger.warning('Skipping malformed song document ${doc.id}: $e');
      }
    }
    return songs;
  }
}
