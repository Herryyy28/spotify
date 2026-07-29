import 'package:harmony_music/core/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:io';
import '../models/song_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
      );
    } catch (e) {
      AppLogger.warning('Error setting Firestore persistence: $e');
    }
  }

  String? get userId => _auth.currentUser?.uid;
  String? get displayName => _auth.currentUser?.displayName;

  // ============= AUTHENTICATION =============

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _cacheUserData(result.user!);
      return result.user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signUpWithEmail(
      String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile
      await createUserProfile(result.user!.uid, {
        'name': name,
        'email': email,
      });

      await _cacheUserData(result.user!);
      return result.user;
    } catch (e) {
      throw Exception('FirebaseService Signup failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<User?> signInWithGoogle() async {
    // Implement Google Sign-In
    throw UnimplementedError();
  }

  Future<User?> signInWithApple() async {
    // Implement Apple Sign-In
    throw UnimplementedError();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ============= SONGS =============

  Future<List<Song>> getSongs({
    int limit = 50,
    String? lastSongId,
    List<String>? genres,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('songs')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (genres != null && genres.isNotEmpty) {
        query = query.where('genres', arrayContainsAny: genres);
      }

      if (lastSongId != null) {
        final lastDoc =
            await _firestore.collection('songs').doc(lastSongId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Song.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get songs: $e');
    }
  }

  Future<Song> getSong(String id) async {
    try {
      final doc = await _firestore.collection('songs').doc(id).get();
      final data = doc.data()!;
      data['id'] = doc.id;
      return Song.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get song: $e');
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    try {
      // Implement Firebase search
      final snapshot = await _firestore
          .collection('songs')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Song.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search songs: $e');
    }
  }

  // ============= STREAMS =============

  Stream<List<Song>> getSongsStream({int limit = 50}) {
    return _firestore
        .collection('songs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Song.fromJson(data);
      }).toList();
    });
  }

  Future<void> addSong(Song song) async {
    try {
      await _firestore.collection('songs').doc(song.id).set({
        ...song.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add song to Firestore: $e');
    }
  }

  Future<void> updateSong(Song song) async {
    try {
      final data = song.toJson();
      data.remove('createdAt'); // Preserve original creation time
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('songs').doc(song.id).update(data);
    } catch (e) {
      throw Exception('Failed to update song: $e');
    }
  }

  Future<void> deleteSong(String songId) async {
    try {
      await _firestore.collection('songs').doc(songId).delete();
    } catch (e) {
      throw Exception('Failed to delete song: $e');
    }
  }

  Future<void> incrementPlayCount(String songId) async {
    try {
      await _firestore.collection('songs').doc(songId).update({
        'playCount': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.error('Failed to increment play count: $e');
    }
  }

  Future<void> likeSong(String songId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('likedSongs')
          .doc(songId)
          .set({'likedAt': FieldValue.serverTimestamp()});

      await _firestore.collection('songs').doc(songId).update({
        'likeCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to like song: $e');
    }
  }

  Future<void> unlikeSong(String songId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('likedSongs')
          .doc(songId)
          .delete();

      await _firestore.collection('songs').doc(songId).update({
        'likeCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to unlike song: $e');
    }
  }

  // ============= ARTISTS =============

  Future<Artist> getArtist(String id) async {
    try {
      final doc = await _firestore.collection('artists').doc(id).get();
      final data = doc.data()!;
      data['id'] = doc.id;
      return Artist.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get artist: $e');
    }
  }

  Future<List<Song>> getArtistTopSongs(String artistId,
      {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('songs')
          .where('artistId', isEqualTo: artistId)
          .orderBy('playCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Song.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get artist songs: $e');
    }
  }

  Future<void> followArtist(String artistId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(artistId)
          .set({'followedAt': FieldValue.serverTimestamp()});

      await _firestore.collection('artists').doc(artistId).update({
        'followersCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to follow artist: $e');
    }
  }

  // ============= PLAYLISTS =============

  Future<Playlist> createPlaylist(Playlist playlist) async {
    try {
      final docRef = await _firestore.collection('playlists').add({
        ...playlist.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      final data = doc.data()!;
      data['id'] = doc.id;
      return Playlist.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create playlist: $e');
    }
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    try {
      final data = playlist.toJson();
      data.remove('createdAt');
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('playlists').doc(playlist.id).update(data);
    } catch (e) {
      throw Exception('Failed to update playlist: $e');
    }
  }

  Future<List<Playlist>> getUserPlaylists(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Playlist.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get playlists: $e');
    }
  }

  Future<Playlist> getPlaylist(String id) async {
    try {
      final doc = await _firestore.collection('playlists').doc(id).get();
      final data = doc.data()!;
      data['id'] = doc.id;

      // Fetch songs
      final songsList = data['songs'] as List? ?? [];
      final songs = await Future.wait(
          songsList.map((songId) => getSong(songId as String)));
      data['songs'] = songs.map((s) => s.toJson()).toList();

      return Playlist.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get playlist: $e');
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'songs': FieldValue.arrayUnion([songId]),
        'songCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add song to playlist: $e');
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'songs': FieldValue.arrayRemove([songId]),
        'songCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove song from playlist: $e');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).delete();
    } catch (e) {
      throw Exception('Failed to delete playlist: $e');
    }
  }

  // ============= RECOMMENDATIONS =============

  Future<List<Song>> getRecommendations(String userId) async {
    try {
      // Get user's listening history
      final history = await _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .orderBy('playedAt', descending: true)
          .limit(50)
          .get();

      final playedSongs =
          history.docs.map((doc) => doc['songId'] as String).toList();

      if (playedSongs.isEmpty) {
        // Return popular songs if no history
        return getPopularSongs();
      }

      // Get genres from played songs
      final genres = <String>{};
      for (final songId in playedSongs.take(10)) {
        final song = await getSong(songId);
        genres.addAll(song.genres);
      }

      // Get recommendations based on genres
      return getSongs(
        genres: genres.toList(),
        limit: 20,
      );
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  Future<List<Song>> getPopularSongs({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('songs')
          .orderBy('playCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Song.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get popular songs: $e');
    }
  }

  Future<List<Song>> getRecentlyPlayed(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .orderBy('playedAt', descending: true)
          .limit(20)
          .get();

      final songs = <Song>[];
      for (final doc in snapshot.docs) {
        final song = await getSong(doc['songId']);
        songs.add(song);
      }

      return songs;
    } catch (e) {
      throw Exception('Failed to get recently played: $e');
    }
  }

  // ============= UPLOAD =============

  Future<String> uploadSong({
    required String filePath,
    required String fileName,
    required String userId,
  }) async {
    if (kIsWeb) throw UnsupportedError('Use uploadSongBytes() on Web platforms.');
    try {
      final ref = _storage
          .ref()
          .child('songs')
          .child(userId)
          .child('$fileName-${DateTime.now().millisecondsSinceEpoch}.mp3');

      // ignore: avoid_dynamic_calls
      final uploadTask = await ref.putFile(File(filePath));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload song: $e');
    }
  }

  /// Web-compatible MP3 upload using raw bytes (works on Flutter Web).
  Future<String> uploadSongBytes({
    required Uint8List bytes,
    required String fileName,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('songs')
          .child(userId)
          .child('${fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.mp3');

      final metadata = SettableMetadata(contentType: 'audio/mpeg');
      final task = ref.putData(bytes, metadata);

      if (onProgress != null) {
        task.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            onProgress(event.bytesTransferred / event.totalBytes);
          }
        });
      }

      final snapshot = await task.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw Exception('Upload timed out (2 min). Network speed may be slow or CORS is blocking Firebase Storage. Try using an Audio URL instead.'),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload song bytes: $e');
    }
  }

  /// Web-compatible image upload using raw bytes (works on Flutter Web).
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    required String userId,
    String folder = 'covers',
    String contentType = 'image/jpeg',
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child(folder)
          .child(userId)
          .child('${fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}');

      final metadata = SettableMetadata(contentType: contentType);
      final task = ref.putData(bytes, metadata);

      if (onProgress != null) {
        task.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            onProgress(event.bytesTransferred / event.totalBytes);
          }
        });
      }

      final snapshot = await task.timeout(
        const Duration(minutes: 1),
        onTimeout: () => throw Exception('Image upload timed out (1 min). Check your connection or use a Cover URL.'),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image bytes: $e');
    }
  }

  // ============= USER PROFILE =============

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'photoUrl': data['photoUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'premium': false,
        'isAdmin': false, // Set to true manually in Firebase console for admin users
        'preferences': {
          'theme': 'system',
          'quality': 'high',
          'downloadQuality': 'high',
          'autoPlay': true,
          'explicitContent': true,
        },
        'stats': {
          'songsPlayed': 0,
          'totalListeningTime': 0,
          'playlistsCreated': 0,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Firestore error creating profile: $e');
      throw Exception('Failed to create user profile in Firestore: $e');
    }
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();
      final userDoc = _firestore.collection('users').doc(userId);

      // 1. Delete liked songs
      final likedSongs = await userDoc.collection('likedSongs').get();
      for (var doc in likedSongs.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete history
      final history = await userDoc.collection('history').get();
      for (var doc in history.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete following
      final following = await userDoc.collection('following').get();
      for (var doc in following.docs) {
        batch.delete(doc.reference);
      }

      // 4. Delete user document
      batch.delete(userDoc);

      await batch.commit();

      // Note: In a real app, you might also want to delete the user's uploaded songs in Storage
      // and their playlists.
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  // ============= STREAMS =============

  Future<void> logListeningEvent({
    required String userId,
    required String songId,
    required int duration,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .add({
        'songId': songId,
        'playedAt': FieldValue.serverTimestamp(),
        'duration': duration,
      });

      // Update user stats
      await _firestore.collection('users').doc(userId).update({
        'stats.songsPlayed': FieldValue.increment(1),
        'stats.totalListeningTime': FieldValue.increment(duration),
      });

      // Update song play count
      await incrementPlayCount(songId);
    } catch (e) {
      AppLogger.error('Failed to log listening event: $e');
    }
  }

  // ============= CACHE MANAGEMENT =============

  Future<void> _cacheUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.uid);
    await prefs.setString('email', user.email ?? '');
    await prefs.setString('displayName', user.displayName ?? '');
    await prefs.setString('photoURL', user.photoURL ?? '');
  }

  // ============= ERROR HANDLING =============

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'Email is already in use.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Email is invalid.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred.';
  }
}
