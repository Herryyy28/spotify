import 'package:hive/hive.dart';


@HiveType(typeId: 3)
class Podcast {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String publisher;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String? coverUrl;

  @HiveField(5)
  final List<Episode> episodes;

  @HiveField(6)
  final int episodeCount;

  @HiveField(7)
  final int subscribers;

  @HiveField(8)
  final List<String> categories;

  @HiveField(9)
  final String? language;

  @HiveField(10)
  final bool isExplicit;

  @HiveField(11)
  final String? website;

  @HiveField(12)
  final DateTime? lastUpdated;

  @HiveField(13)
  final double averageRating;

  @HiveField(14)
  final int totalRatings;

  Podcast({
    required this.id,
    required this.title,
    required this.publisher,
    this.description,
    this.coverUrl,
    this.episodes = const <Episode>[],
    this.episodeCount = 0,
    this.subscribers = 0,
    this.categories = const <String>[],
    this.language,
    this.isExplicit = false,
    this.website,
    this.lastUpdated,
    this.averageRating = 0.0,
    this.totalRatings = 0,
  });

  Podcast copyWith({
    String? id,
    String? title,
    String? publisher,
    String? description,
    String? coverUrl,
    List<Episode>? episodes,
    int? episodeCount,
    int? subscribers,
    List<String>? categories,
    String? language,
    bool? isExplicit,
    String? website,
    DateTime? lastUpdated,
    double? averageRating,
    int? totalRatings,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      publisher: publisher ?? this.publisher,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      episodes: episodes ?? this.episodes,
      episodeCount: episodeCount ?? this.episodeCount,
      subscribers: subscribers ?? this.subscribers,
      categories: categories ?? this.categories,
      language: language ?? this.language,
      isExplicit: isExplicit ?? this.isExplicit,
      website: website ?? this.website,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }
}

@HiveType(typeId: 4)
class Episode {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String audioUrl;

  @HiveField(4)
  final int duration;

  @HiveField(5)
  final DateTime publishDate;

  @HiveField(6)
  final bool isExplicit;

  @HiveField(7)
  final int playCount;

  @HiveField(8)
  final int likeCount;

  @HiveField(9)
  final String? imageUrl;

  @HiveField(10)
  final bool isDownloaded;

  Episode({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.duration,
    required this.publishDate,
    this.isExplicit = false,
    this.playCount = 0,
    this.likeCount = 0,
    this.imageUrl,
    this.isDownloaded = false,
  });

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
    return '$minutes:${(duration % 60).toString().padLeft(2, '0')}';
  }
}
