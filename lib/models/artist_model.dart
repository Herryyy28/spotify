import 'package:hive/hive.dart';

part 'artist_model.g.dart';

@HiveType(typeId: 1)
class Artist {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? bio;

  @HiveField(3)
  final String? imageUrl;

  @HiveField(4)
  final int monthlyListeners;

  @HiveField(5)
  final List<String> genres;

  @HiveField(6)
  final List<String> topSongs;

  @HiveField(7)
  final List<String> albums;

  @HiveField(8)
  final int followersCount;

  @HiveField(9)
  final bool isVerified;

  @HiveField(10)
  final String? website;

  @HiveField(11)
  final String? facebookUrl;

  @HiveField(12)
  final String? twitterUrl;

  @HiveField(13)
  final String? instagramUrl;

  @HiveField(14)
  final DateTime? createdAt;

  @HiveField(15)
  final DateTime? updatedAt;

  Artist({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
    this.monthlyListeners = 0,
    this.genres = const [],
    this.topSongs = const [],
    this.albums = const [],
    this.followersCount = 0,
    this.isVerified = false,
    this.website,
    this.facebookUrl,
    this.twitterUrl,
    this.instagramUrl,
    this.createdAt,
    this.updatedAt,
  });

  Artist copyWith({
    String? id,
    String? name,
    String? bio,
    String? imageUrl,
    int? monthlyListeners,
    List<String>? genres,
    List<String>? topSongs,
    List<String>? albums,
    int? followersCount,
    bool? isVerified,
    String? website,
    String? facebookUrl,
    String? twitterUrl,
    String? instagramUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      monthlyListeners: monthlyListeners ?? this.monthlyListeners,
      genres: genres ?? this.genres,
      topSongs: topSongs ?? this.topSongs,
      albums: albums ?? this.albums,
      followersCount: followersCount ?? this.followersCount,
      isVerified: isVerified ?? this.isVerified,
      website: website ?? this.website,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'imageUrl': imageUrl,
      'monthlyListeners': monthlyListeners,
      'genres': genres,
      'topSongs': topSongs,
      'albums': albums,
      'followersCount': followersCount,
      'isVerified': isVerified,
      'website': website,
      'facebookUrl': facebookUrl,
      'twitterUrl': twitterUrl,
      'instagramUrl': instagramUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'],
      name: json['name'],
      bio: json['bio'],
      imageUrl: json['imageUrl'],
      monthlyListeners: json['monthlyListeners'] ?? 0,
      genres: List<String>.from(json['genres'] ?? []),
      topSongs: List<String>.from(json['topSongs'] ?? []),
      albums: List<String>.from(json['albums'] ?? []),
      followersCount: json['followersCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      website: json['website'],
      facebookUrl: json['facebookUrl'],
      twitterUrl: json['twitterUrl'],
      instagramUrl: json['instagramUrl'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  String getFormattedListeners() {
    if (monthlyListeners >= 1000000) {
      return '${(monthlyListeners / 1000000).toStringAsFixed(1)}M';
    } else if (monthlyListeners >= 1000) {
      return '${(monthlyListeners / 1000).toStringAsFixed(1)}K';
    } else {
      return monthlyListeners.toString();
    }
  }
}
