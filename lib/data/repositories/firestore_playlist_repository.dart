import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/logger.dart';
import '../../models/playlist_model.dart';
import 'playlist_repository.dart';

class FirestorePlaylistRepository implements PlaylistRepository {
  final FirebaseFirestore _db;

  FirestorePlaylistRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const String _collection = 'playlists';

  @override
  Future<List<Playlist>> getUserPlaylists(String userId) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return _mapDocs(snapshot.docs);
    } catch (e) {
      AppLogger.error('FirestorePlaylistRepository.getUserPlaylists failed: $e');
      return [];
    }
  }

  @override
  Future<List<Playlist>> getFeaturedPlaylists({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return _mapDocs(snapshot.docs);
    } catch (e) {
      AppLogger.error('FirestorePlaylistRepository.getFeaturedPlaylists failed: $e');
      return [];
    }
  }

  @override
  Future<List<Playlist>> getRecommendedPlaylists({int limit = 10}) async {
    try {
      // In a real app, this would be personalized. For now, fetch latest public playlists
      final snapshot = await _db
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return _mapDocs(snapshot.docs);
    } catch (e) {
      AppLogger.error('FirestorePlaylistRepository.getRecommendedPlaylists failed: $e');
      return [];
    }
  }

  @override
  Future<List<Playlist>> getChartPlaylists({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: 'Top')
          .where('name', isLessThan: 'Top\uf8ff')
          .limit(limit)
          .get();
      return _mapDocs(snapshot.docs);
    } catch (e) {
      AppLogger.error('FirestorePlaylistRepository.getChartPlaylists failed: $e');
      return [];
    }
  }

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Playlist.fromJson(data);
      }
    } catch (e) {
      AppLogger.error('FirestorePlaylistRepository.getPlaylistById failed: $e');
    }
    return null;
  }

  @override
  Future<Playlist> createPlaylist(Playlist playlist) async {
    final docRef = _db.collection(_collection).doc();
    final newPlaylist = playlist.copyWith(id: docRef.id);
    await docRef.set({
      ...newPlaylist.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return newPlaylist;
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) async {
    final data = playlist.toJson()..remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(_collection).doc(playlist.id).update(data);
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _db.collection(_collection).doc(playlistId).delete();
  }

  @override
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    // In actual implementation, we might want to store song IDs in a subcollection or array.
    // For this app's current model, the songs list is stored in the document directly.
    // However, updating nested arrays in Firestore is tricky without reading first.
    throw UnimplementedError('Use updatePlaylist with the full modified songs list instead');
  }

  @override
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    throw UnimplementedError('Use updatePlaylist with the full modified songs list instead');
  }

  List<Playlist> _mapDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final playlists = <Playlist>[];
    for (final doc in docs) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        playlists.add(Playlist.fromJson(data));
      } catch (e) {
        AppLogger.warning('Skipping malformed playlist document ${doc.id}: $e');
      }
    }
    return playlists;
  }
}
