import 'package:hive/hive.dart';
import 'song_model.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 2)
class Playlist {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? coverUrl;

  @HiveField(4)
  final String userId;

  @HiveField(5)
  final String userName;

  @HiveField(6)
  final List<Song> songs;

  @HiveField(7)
  int songCount;

  @HiveField(8)
  int totalDuration;

  @HiveField(9)
  final int followersCount;

  @HiveField(10)
  final bool isPublic;

  @HiveField(11)
  final bool isCollaborative;

  @HiveField(12)
  final List<String> collaborators;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  @HiveField(15)
  final String? color;

  @HiveField(16)
  final List<String> tags;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.userId,
    required this.userName,
    List<Song>? songs,
    this.songCount = 0,
    this.totalDuration = 0,
    this.followersCount = 0,
    this.isPublic = true,
    this.isCollaborative = false,
    List<String>? collaborators,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    List<String>? tags,
  })  : songs = songs ?? [],
        collaborators = collaborators ?? [],
        tags = tags ?? [];

  int get durationInMinutes => totalDuration ~/ 60;

  String get formattedDuration {
    final hours = durationInMinutes ~/ 60;
    final minutes = durationInMinutes % 60;
    if (hours > 0) {
      return '${hours}h $minutes min';
    }
    return '$minutes min';
  }

  // Helper getter for compatibility with AI services
  String get imageUrl => coverUrl ?? '';

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    String? userId,
    String? userName,
    List<Song>? songs,
    int? songCount,
    int? totalDuration,
    int? followersCount,
    bool? isPublic,
    bool? isCollaborative,
    List<String>? collaborators,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    List<String>? tags,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      songs: songs ?? this.songs,
      songCount: songCount ?? this.songCount,
      totalDuration: totalDuration ?? this.totalDuration,
      followersCount: followersCount ?? this.followersCount,
      isPublic: isPublic ?? this.isPublic,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      collaborators: collaborators ?? this.collaborators,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'userId': userId,
      'userName': userName,
      'songs': songs.map((s) => s.toJson()).toList(),
      'songCount': songCount,
      'totalDuration': totalDuration,
      'followersCount': followersCount,
      'isPublic': isPublic,
      'isCollaborative': isCollaborative,
      'collaborators': collaborators,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
      'tags': tags,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coverUrl: json['coverUrl'],
      userId: json['userId'],
      userName: json['userName'],
      songs: (json['songs'] as List).map((s) => Song.fromJson(s)).toList(),
      songCount: json['songCount'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      followersCount: json['followersCount'] ?? 0,
      isPublic: json['isPublic'] ?? true,
      isCollaborative: json['isCollaborative'] ?? false,
      collaborators: List<String>.from(json['collaborators'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      color: json['color'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
