import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harmony_music/core/utils/logger.dart';
import '../models/listening_room_model.dart';
import '../models/song_model.dart';

class ListeningRoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? 'guest_user';
  String get currentUserName => _auth.currentUser?.displayName ?? 'Guest Listener';

  /// Creates a new listening room document in Firestore.
  Future<ListeningRoom> createRoom({
    required Song song,
    required String hostName,
    String? hostPhotoUrl,
  }) async {
    final roomId = 'ROOM-${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
    final room = ListeningRoom(
      id: roomId,
      hostId: currentUserId,
      hostName: hostName.isEmpty ? currentUserName : hostName,
      hostPhotoUrl: hostPhotoUrl,
      currentSong: song,
      positionInSeconds: 0,
      isPlaying: true,
      participantCount: 1,
      activeUserIds: [currentUserId],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _firestore.collection('listening_rooms').doc(roomId).set(room.toJson());
      AppLogger.info('Created listening room: $roomId');
    } catch (e) {
      AppLogger.error('Firestore create room error: $e');
    }

    return room;
  }

  /// Streams real-time updates for a room.
  Stream<ListeningRoom?> streamRoom(String roomId) {
    return _firestore.collection('listening_rooms').doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ListeningRoom.fromJson(snapshot.data()!);
    });
  }

  /// Syncs current host playback state (Song, timestamp position, isPlaying state).
  Future<void> updateRoomPlayback({
    required String roomId,
    required Song song,
    required double positionInSeconds,
    required bool isPlaying,
  }) async {
    try {
      await _firestore.collection('listening_rooms').doc(roomId).update({
        'currentSong': song.toJson(),
        'positionInSeconds': positionInSeconds,
        'isPlaying': isPlaying,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Error updating room playback: $e');
    }
  }

  /// Sends a live reaction/message in the room.
  Future<void> sendRoomMessage({
    required String roomId,
    required String message,
    bool isEmojiOnly = false,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final roomMessage = RoomMessage(
      id: messageId,
      senderId: currentUserId,
      senderName: currentUserName,
      message: message,
      isEmojiOnly: isEmojiOnly,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore
          .collection('listening_rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .set(roomMessage.toJson());
    } catch (e) {
      AppLogger.error('Error sending room message: $e');
    }
  }

  /// Streams live messages/reactions for a room.
  Stream<List<RoomMessage>> streamRoomMessages(String roomId) {
    return _firestore
        .collection('listening_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RoomMessage.fromJson(doc.data())).toList();
    });
  }

  /// Leaves or deletes a room if host.
  Future<void> leaveRoom(String roomId, bool isHost) async {
    try {
      if (isHost) {
        await _firestore.collection('listening_rooms').doc(roomId).delete();
      } else {
        await _firestore.collection('listening_rooms').doc(roomId).update({
          'participantCount': FieldValue.increment(-1),
          'activeUserIds': FieldValue.arrayRemove([currentUserId]),
        });
      }
    } catch (e) {
      AppLogger.error('Error leaving room: $e');
    }
  }
}
