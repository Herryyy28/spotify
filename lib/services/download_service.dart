import 'package:harmony_music/core/utils/logger.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/song_model.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamController<DownloadProgress>> _progressControllers =
      {};

  final Box _downloadBox = Hive.box('downloads');
  final CacheManager _cacheManager = CacheManager(
    Config(
      'download_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
    ),
  );

  // Stream for download progress
  Stream<DownloadProgress> getDownloadProgress(String downloadId) {
    if (!_progressControllers.containsKey(downloadId)) {
      _progressControllers[downloadId] = StreamController.broadcast();
    }
    return _progressControllers[downloadId]!.stream;
  }

  // Download song
  Future<DownloadResult> downloadSong(
    Song song, {
    DownloadQuality quality = DownloadQuality.high,
  }) async {
    String? downloadId;
    try {
      // Check permission
      if (!await _requestStoragePermission()) {
        return DownloadResult(
          success: false,
          error: 'Storage permission denied',
        );
      }

      downloadId = '${song.id}_${DateTime.now().millisecondsSinceEpoch}';
      final currentDownloadId = downloadId;
      final cancelToken = CancelToken();
      _cancelTokens[downloadId] = cancelToken;

      // Get download directory
      final dir = await _getDownloadDirectory();
      final fileName = '${song.id}_${song.title}.mp3';
      final filePath = '${dir.path}/$fileName';

      // Check if already downloaded
      if (await File(filePath).exists()) {
        return DownloadResult(
          success: true,
          filePath: filePath,
          downloadId: downloadId,
        );
      }

      // Download file
      final response = await _dio.download(
        song.audioUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final progress = received / total;
          final progressData = DownloadProgress(
            downloadId: currentDownloadId,
            received: received,
            total: total,
            progress: progress,
            speed: _calculateSpeed(received, total),
          );

          if (_progressControllers.containsKey(currentDownloadId)) {
            _progressControllers[currentDownloadId]!.add(progressData);
          }
        },
      );

      if (response.statusCode == 200) {
        // Save download info to Hive
        await _downloadBox.put(song.id, {
          'id': song.id,
          'title': song.title,
          'artist': song.artist,
          'filePath': filePath,
          'downloadDate': DateTime.now().toIso8601String(),
          'quality': quality.toString(),
          'coverUrl': song.coverUrl,
        });

        return DownloadResult(
          success: true,
          filePath: filePath,
          downloadId: downloadId,
        );
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      return DownloadResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      if (downloadId != null) {
        _cancelTokens.remove(downloadId);
        _progressControllers[downloadId]?.close();
        _progressControllers.remove(downloadId);
      }
    }
  }

  // Download multiple songs
  Future<List<DownloadResult>> downloadPlaylist(List<Song> songs) async {
    final results = <DownloadResult>[];
    for (final song in songs) {
      final result = await downloadSong(song);
      results.add(result);
      await Future.delayed(const Duration(milliseconds: 500)); // Rate limiting
    }
    return results;
  }

  // Cancel download
  void cancelDownload(String downloadId) {
    _cancelTokens[downloadId]?.cancel();
    _cancelTokens.remove(downloadId);
    _progressControllers[downloadId]?.close();
    _progressControllers.remove(downloadId);
  }

  // Pause download (implement for resumable downloads)
  Future<void> pauseDownload(String downloadId) async {
    // Implementation for resumable downloads
  }

  // Resume download
  Future<void> resumeDownload(String downloadId) async {
    // Implementation for resumable downloads
  }

  // Get downloaded songs
  List<DownloadedSong> getDownloadedSongs() {
    final downloads = <DownloadedSong>[];
    for (final key in _downloadBox.keys) {
      final data = _downloadBox.get(key);
      downloads.add(DownloadedSong.fromMap(data));
    }
    return downloads;
  }

  // Delete downloaded song
  Future<bool> deleteDownloadedSong(String songId) async {
    try {
      final data = _downloadBox.get(songId);
      if (data != null) {
        final file = File(data['filePath']);
        if (await file.exists()) {
          await file.delete();
        }
        await _downloadBox.delete(songId);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting download: $e');
      return false;
    }
  }

  // Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      for (final key in _downloadBox.keys) {
        await deleteDownloadedSong(key as String);
      }
    } catch (e) {
      AppLogger.error('Error clearing downloads: $e');
    }
  }

  // Check if song is downloaded
  bool isSongDownloaded(String songId) {
    return _downloadBox.containsKey(songId);
  }

  // Get local file path for downloaded song
  Future<String?> getLocalFilePath(String songId) async {
    final data = _downloadBox.get(songId);
    if (data != null) {
      final file = File(data['filePath']);
      if (await file.exists()) {
        return data['filePath'];
      }
    }
    return null;
  }

  // Get download directory
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download/HarmonyMusic');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  // Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  // Calculate download speed
  double _calculateSpeed(int received, int total) {
    // Implementation for speed calculation
    return 0.0;
  }

  // Dispose
  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _cancelTokens.clear();
    _progressControllers.clear();
  }
}

// Models
enum DownloadQuality {
  low,
  medium,
  high,
  lossless,
}

class DownloadProgress {
  final String downloadId;
  final int received;
  final int total;
  final double progress;
  final double speed;

  DownloadProgress({
    required this.downloadId,
    required this.received,
    required this.total,
    required this.progress,
    required this.speed,
  });

  String get formattedProgress => '${(progress * 100).toStringAsFixed(1)}%';

  String get formattedReceived => _formatBytes(received);

  String get formattedTotal => _formatBytes(total);

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? downloadId;
  final String? error;

  DownloadResult({
    required this.success,
    this.filePath,
    this.downloadId,
    this.error,
  });
}

class DownloadedSong {
  final String id;
  final String title;
  final String artist;
  final String filePath;
  final DateTime downloadDate;
  final DownloadQuality quality;
  final String coverUrl;

  DownloadedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    required this.downloadDate,
    required this.quality,
    required this.coverUrl,
  });

  factory DownloadedSong.fromMap(Map<String, dynamic> map) {
    return DownloadedSong(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      filePath: map['filePath'],
      downloadDate: DateTime.parse(map['downloadDate']),
      quality: DownloadQuality.values.firstWhere(
        (q) => q.toString() == map['quality'],
        orElse: () => DownloadQuality.high,
      ),
      coverUrl: map['coverUrl'],
    );
  }
}
