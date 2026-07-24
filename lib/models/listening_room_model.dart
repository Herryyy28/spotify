import '../models/song_model.dart';

class ListeningRoom {
  final String id;
  final String hostId;
  final String hostName;
  final String? hostPhotoUrl;
  final Song currentSong;
  final double positionInSeconds;
  final bool isPlaying;
  final int participantCount;
  final List<String> activeUserIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  ListeningRoom({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostPhotoUrl,
    required this.currentSong,
    required this.positionInSeconds,
    required this.isPlaying,
    this.participantCount = 1,
    this.activeUserIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoUrl': hostPhotoUrl,
      'currentSong': currentSong.toJson(),
      'positionInSeconds': positionInSeconds,
      'isPlaying': isPlaying,
      'participantCount': participantCount,
      'activeUserIds': activeUserIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ListeningRoom.fromJson(Map<String, dynamic> json) {
    return ListeningRoom(
      id: json['id'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      hostName: json['hostName'] as String? ?? 'Host',
      hostPhotoUrl: json['hostPhotoUrl'] as String?,
      currentSong: json['currentSong'] != null
          ? Song.fromJson(json['currentSong'] as Map<String, dynamic>)
          : Song(
              id: 'demo_room_song',
              title: 'Welcome to Listening Room',
              artist: 'Sync Music',
              album: 'Live Room',
              duration: '3:30',
              durationInSeconds: 210,
              audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
              coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
              releaseDate: DateTime.now(),
            ),
      positionInSeconds: (json['positionInSeconds'] as num?)?.toDouble() ?? 0.0,
      isPlaying: json['isPlaying'] as bool? ?? true,
      participantCount: json['participantCount'] as int? ?? 1,
      activeUserIds: (json['activeUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class RoomMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final bool isEmojiOnly;
  final DateTime timestamp;

  RoomMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.isEmojiOnly = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'isEmojiOnly': isEmojiOnly,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    return RoomMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'User',
      message: json['message'] as String? ?? '',
      isEmojiOnly: json['isEmojiOnly'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
