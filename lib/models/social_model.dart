import '../models/song_model.dart';

class FriendProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isFollowing;
  final int followersCount;
  final int followingCount;
  final Song? currentlyListening;
  final DateTime? lastActive;

  const FriendProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isFollowing = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.currentlyListening,
    this.lastActive,
  });

  FriendProfile copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isFollowing,
    int? followersCount,
    int? followingCount,
    Song? currentlyListening,
    DateTime? lastActive,
  }) {
    return FriendProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      currentlyListening: currentlyListening ?? this.currentlyListening,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
      isFollowing: json['isFollowing'] ?? false,
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isFollowing': isFollowing,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'lastActive': lastActive?.toIso8601String(),
    };
  }
}

class UserActivity {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final Song song;
  final DateTime timestamp;
  final ActivityType type;

  const UserActivity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.song,
    required this.timestamp,
    this.type = ActivityType.played,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json, Song song) {
    return UserActivity(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      song: song,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      type: ActivityType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'played'),
        orElse: () => ActivityType.played,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'songId': song.id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

enum ActivityType {
  played,
  liked,
  shared,
  addedToPlaylist,
}
