import 'package:harmony_music/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_model.dart';
import '../models/song_model.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ========== FOLLOW/UNFOLLOW ==========

  Future<void> followUser(String targetUserId) async {
    if (_uid == null) return;
    try {
      final batch = _firestore.batch();

      // Add to my following list
      batch.set(
        _firestore.doc('users/$_uid/following/$targetUserId'),
        {'userId': targetUserId, 'followedAt': FieldValue.serverTimestamp()},
      );

      // Add me to their followers list
      batch.set(
        _firestore.doc('users/$targetUserId/followers/$_uid'),
        {'userId': _uid, 'followedAt': FieldValue.serverTimestamp()},
      );

      // Update counts
      batch.update(
        _firestore.doc('users/$_uid'),
        {'followingCount': FieldValue.increment(1)},
      );
      batch.update(
        _firestore.doc('users/$targetUserId'),
        {'followersCount': FieldValue.increment(1)},
      );

      await batch.commit();
      AppLogger.info('Followed user $targetUserId');
    } catch (e) {
      AppLogger.error('Error following user: $e');
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    if (_uid == null) return;
    try {
      final batch = _firestore.batch();

      batch.delete(_firestore.doc('users/$_uid/following/$targetUserId'));
      batch.delete(_firestore.doc('users/$targetUserId/followers/$_uid'));

      batch.update(
        _firestore.doc('users/$_uid'),
        {'followingCount': FieldValue.increment(-1)},
      );
      batch.update(
        _firestore.doc('users/$targetUserId'),
        {'followersCount': FieldValue.increment(-1)},
      );

      await batch.commit();
      AppLogger.info('Unfollowed user $targetUserId');
    } catch (e) {
      AppLogger.error('Error unfollowing user: $e');
    }
  }

  Future<bool> isFollowing(String targetUserId) async {
    if (_uid == null) return false;
    try {
      final doc = await _firestore
          .doc('users/$_uid/following/$targetUserId')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ========== FETCH SOCIAL DATA ==========

  Future<List<FriendProfile>> getFollowing() async {
    if (_uid == null) return [];
    try {
      final snap = await _firestore
          .collection('users/$_uid/following')
          .limit(50)
          .get();

      final profiles = <FriendProfile>[];
      for (final doc in snap.docs) {
        final userId = doc.data()['userId'] as String;
        final profile = await _getUserProfile(userId);
        if (profile != null) profiles.add(profile);
      }
      return profiles;
    } catch (e) {
      AppLogger.error('Error getting following: $e');
      return [];
    }
  }

  Future<List<FriendProfile>> getFollowers() async {
    if (_uid == null) return [];
    try {
      final snap = await _firestore
          .collection('users/$_uid/followers')
          .limit(50)
          .get();

      final profiles = <FriendProfile>[];
      for (final doc in snap.docs) {
        final userId = doc.data()['userId'] as String;
        final profile = await _getUserProfile(userId);
        if (profile != null) profiles.add(profile);
      }
      return profiles;
    } catch (e) {
      AppLogger.error('Error getting followers: $e');
      return [];
    }
  }

  Future<FriendProfile?> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.doc('users/$userId').get();
      if (!doc.exists) return null;
      return FriendProfile.fromJson({...doc.data()!, 'id': userId});
    } catch (e) {
      return null;
    }
  }

  Future<List<UserActivity>> getFriendsActivity() async {
    if (_uid == null) return [];
    try {
      final followingSnap = await _firestore
          .collection('users/$_uid/following')
          .get();
      final followingIds = followingSnap.docs
          .map((d) => d.data()['userId'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      final activitySnap = await _firestore
          .collection('activity')
          .where('userId', whereIn: followingIds.take(10).toList())
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      final activities = <UserActivity>[];
      for (final doc in activitySnap.docs) {
        final data = doc.data();
        final songData = data['song'] as Map<String, dynamic>?;
        if (songData != null) {
          try {
            final song = Song.fromJson(songData);
            activities.add(UserActivity.fromJson({...data, 'id': doc.id}, song));
          } catch (e) {
            AppLogger.error('Error parsing activity: $e');
          }
        }
      }
      return activities;
    } catch (e) {
      AppLogger.error('Error getting friends activity: $e');
      return [];
    }
  }

  // ========== POST ACTIVITY ==========

  Future<void> postActivity(Song song, ActivityType type) async {
    if (_uid == null) return;
    try {
      final userData = await _firestore.doc('users/$_uid').get();
      final userName = userData.data()?['displayName'] ?? 'Unknown';

      await _firestore.collection('activity').add({
        'userId': _uid,
        'userName': userName,
        'song': song.toJson(),
        'type': type.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error posting activity: $e');
    }
  }
}
