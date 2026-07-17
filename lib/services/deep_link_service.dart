import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song_model.dart';

class DeepLinkService {
  static const String _baseUrl = 'https://harmonymusic.app';

  // ========== GENERATE LINKS ==========

  static String generateSongLink(Song song) {
    return '$_baseUrl/song/${song.id}?title=${Uri.encodeComponent(song.title)}&artist=${Uri.encodeComponent(song.artist)}';
  }

  static String generatePlaylistLink(String playlistId, String playlistName) {
    return '$_baseUrl/playlist/$playlistId?name=${Uri.encodeComponent(playlistName)}';
  }

  // ========== SHARE ==========

  static Future<void> shareSong(Song song) async {
    try {
      final link = generateSongLink(song);
      await Share.share(
        'Listen to "${song.title}" by ${song.artist} on Harmony Music\n$link',
        subject: 'Check out this song on Harmony Music',
      );
      AppLogger.info('Shared song: ${song.title}');
    } catch (e) {
      AppLogger.error('Error sharing song: $e');
    }
  }

  static Future<void> sharePlaylist(String playlistId, String playlistName) async {
    try {
      final link = generatePlaylistLink(playlistId, playlistName);
      await Share.share(
        'Check out the playlist "$playlistName" on Harmony Music\n$link',
        subject: 'Harmony Music Playlist',
      );
    } catch (e) {
      AppLogger.error('Error sharing playlist: $e');
    }
  }

  // ========== PARSE INCOMING LINKS ==========

  static DeepLinkRoute? parseLink(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isEmpty) return null;

      switch (segments[0]) {
        case 'song':
          if (segments.length > 1) {
            return DeepLinkRoute(
              type: DeepLinkType.song,
              id: segments[1],
              params: {for (final e in uri.queryParameters.entries) e.key: e.value},
            );
          }
        case 'playlist':
          if (segments.length > 1) {
            return DeepLinkRoute(
              type: DeepLinkType.playlist,
              id: segments[1],
              params: {for (final e in uri.queryParameters.entries) e.key: e.value},
            );
          }
      }
    } catch (e) {
      AppLogger.error('Error parsing deep link: $e');
    }
    return null;
  }
}

enum DeepLinkType { song, playlist }

class DeepLinkRoute {
  final DeepLinkType type;
  final String id;
  final Map<String, String> params;

  const DeepLinkRoute({
    required this.type,
    required this.id,
    this.params = const {},
  });
}
