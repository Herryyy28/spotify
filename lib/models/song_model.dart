import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class Song {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String duration;

  @HiveField(5)
  final int durationInSeconds;

  @HiveField(6)
  final String audioUrl;

  @HiveField(7)
  final String coverUrl;

  @HiveField(8)
  final String? artistId;

  @HiveField(9)
  final String? albumId;

  @HiveField(10)
  final List<String> genres;

  @HiveField(11)
  final DateTime releaseDate;

  @HiveField(12)
  final int playCount;

  @HiveField(13)
  final int likeCount;

  @HiveField(14)
  final bool isExplicit;

  @HiveField(15)
  final String? lyricsUrl;

  @HiveField(16)
  final String? copyright;

  @HiveField(17)
  final List<String> tags;

  @HiveField(18)
  final int bitrate;

  @HiveField(19)
  final String format;

  @HiveField(20)
  final String? uploadedByAdminId;

  @HiveField(21)
  final DateTime? uploadedAt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.durationInSeconds,
    required this.audioUrl,
    required this.coverUrl,
    this.artistId,
    this.albumId,
    this.genres = const [],
    required this.releaseDate,
    this.playCount = 0,
    this.likeCount = 0,
    this.isExplicit = false,
    this.lyricsUrl,
    this.copyright,
    this.tags = const [],
    this.bitrate = 320,
    this.format = 'mp3',
    this.uploadedByAdminId,
    this.uploadedAt,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? duration,
    int? durationInSeconds,
    String? audioUrl,
    String? coverUrl,
    String? artistId,
    String? albumId,
    List<String>? genres,
    DateTime? releaseDate,
    int? playCount,
    int? likeCount,
    bool? isExplicit,
    String? lyricsUrl,
    String? copyright,
    List<String>? tags,
    int? bitrate,
    String? format,
    String? uploadedByAdminId,
    DateTime? uploadedAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      genres: genres ?? this.genres,
      releaseDate: releaseDate ?? this.releaseDate,
      playCount: playCount ?? this.playCount,
      likeCount: likeCount ?? this.likeCount,
      isExplicit: isExplicit ?? this.isExplicit,
      lyricsUrl: lyricsUrl ?? this.lyricsUrl,
      copyright: copyright ?? this.copyright,
      tags: tags ?? this.tags,
      bitrate: bitrate ?? this.bitrate,
      format: format ?? this.format,
      uploadedByAdminId: uploadedByAdminId ?? this.uploadedByAdminId,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'durationInSeconds': durationInSeconds,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'artistId': artistId,
      'albumId': albumId,
      'genres': genres,
      'releaseDate': releaseDate.toIso8601String(),
      'playCount': playCount,
      'likeCount': likeCount,
      'isExplicit': isExplicit,
      'lyricsUrl': lyricsUrl,
      'copyright': copyright,
      'tags': tags,
      'bitrate': bitrate,
      'format': format,
      'uploadedByAdminId': uploadedByAdminId,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      duration: json['duration'],
      durationInSeconds: json['durationInSeconds'],
      audioUrl: json['audioUrl'],
      coverUrl: json['coverUrl'],
      artistId: json['artistId'],
      albumId: json['albumId'],
      genres: List<String>.from(json['genres'] ?? []),
      releaseDate: DateTime.parse(json['releaseDate']),
      playCount: json['playCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      isExplicit: json['isExplicit'] ?? false,
      lyricsUrl: json['lyricsUrl'],
      copyright: json['copyright'],
      tags: List<String>.from(json['tags'] ?? []),
      bitrate: json['bitrate'] ?? 320,
      format: json['format'] ?? 'mp3',
      uploadedByAdminId: json['uploadedByAdminId'],
      uploadedAt: json['uploadedAt'] != null ? DateTime.tryParse(json['uploadedAt']) : null,
    );
  }

  // Alias for fromJson to support fromMap calls
  factory Song.fromMap(Map<String, dynamic> map) => Song.fromJson(map);

  // Helper getters for compatibility with AI services
  String get imageUrl => coverUrl;
  String get genre => genres.isNotEmpty ? genres.first : 'Unknown';

  String getFormattedDuration() {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
