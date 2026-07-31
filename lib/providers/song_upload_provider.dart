import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/firebase_service.dart';
import '../data/repositories/song_repository.dart';
import '../data/repositories/firestore_song_repository.dart';

/// Tracks which phase of the upload pipeline we're in.
enum UploadPhase {
  idle,
  uploadingAudio,
  uploadingCover,
  savingMetadata,
  done,
  error,
}

class SongUploadProvider extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  final SongRepository _songRepository;

  SongUploadProvider({SongRepository? songRepository})
      : _songRepository = songRepository ?? FirestoreSongRepository();

  // ─── State ───────────────────────────────────────────────────────────────

  UploadPhase _phase = UploadPhase.idle;
  double _audioProgress = 0;
  double _coverProgress = 0;
  String? _errorMessage;
  Song? _lastUploadedSong;

  // ─── Getters ─────────────────────────────────────────────────────────────

  UploadPhase get phase => _phase;
  double get audioProgress => _audioProgress;
  double get coverProgress => _coverProgress;
  String? get errorMessage => _errorMessage;
  Song? get lastUploadedSong => _lastUploadedSong;
  bool get isUploading =>
      _phase == UploadPhase.uploadingAudio ||
      _phase == UploadPhase.uploadingCover ||
      _phase == UploadPhase.savingMetadata;

  String get phaseLabel {
    switch (_phase) {
      case UploadPhase.idle:
        return 'Ready';
      case UploadPhase.uploadingAudio:
        return 'Uploading audio…';
      case UploadPhase.uploadingCover:
        return 'Uploading cover art…';
      case UploadPhase.savingMetadata:
        return 'Saving to library…';
      case UploadPhase.done:
        return 'Upload complete!';
      case UploadPhase.error:
        return 'Upload failed';
    }
  }

  // ─── Core Upload Method ──────────────────────────────────────────────────

  /// Uploads a song.
  ///
  /// Pass [audioBytes]/[audioFileName] for file-based upload,
  /// or pre-fill [audioUrl] on [songTemplate] for URL-based input.
  /// Same for [coverBytes]/[coverFileName] vs [songTemplate.coverUrl].
  Future<Song?> uploadSong({
    required Song songTemplate,
    required String adminUserId,
    Uint8List? audioBytes,
    String? audioFileName,
    Uint8List? coverBytes,
    String? coverFileName,
  }) async {
    try {
      _reset();

      String audioUrl = songTemplate.audioUrl;
      String coverUrl = songTemplate.coverUrl;

      // ── 1. Upload audio file (if bytes provided) ──
      if (audioBytes != null && audioFileName != null) {
        _setPhase(UploadPhase.uploadingAudio);
        audioUrl = await _firebase.uploadSongBytes(
          bytes: audioBytes,
          fileName: audioFileName,
          userId: adminUserId,
          onProgress: (p) {
            _audioProgress = p;
            notifyListeners();
          },
        );
        _audioProgress = 1.0;
        notifyListeners();
      }

      // ── 2. Upload cover art (if bytes provided) ──
      if (coverBytes != null && coverFileName != null) {
        _setPhase(UploadPhase.uploadingCover);
        coverUrl = await _firebase.uploadImageBytes(
          bytes: coverBytes,
          fileName: coverFileName,
          userId: adminUserId,
          folder: 'covers',
          contentType: _mimeFromName(coverFileName),
          onProgress: (p) {
            _coverProgress = p;
            notifyListeners();
          },
        );
        _coverProgress = 1.0;
        notifyListeners();
      }

      // ── 3. Build final Song object ──
      _setPhase(UploadPhase.savingMetadata);
      final song = songTemplate.copyWith(
        id: 'song_${DateTime.now().millisecondsSinceEpoch}',
        audioUrl: audioUrl,
        coverUrl: coverUrl,
        uploadedByAdminId: adminUserId,
        uploadedAt: DateTime.now(),
      );

      // ── 4. Save metadata to Firestore ──
      await _songRepository.addSong(song);

      _lastUploadedSong = song;
      _setPhase(UploadPhase.done);
      return song;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setPhase(UploadPhase.error);
      return null;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void reset() => _reset();

  void _reset() {
    _phase = UploadPhase.idle;
    _audioProgress = 0;
    _coverProgress = 0;
    _errorMessage = null;
    _lastUploadedSong = null;
    notifyListeners();
  }

  void _setPhase(UploadPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  String _mimeFromName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
