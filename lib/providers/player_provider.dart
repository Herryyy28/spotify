import 'dart:async';
import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/audio_service.dart';
import '../services/firebase_service.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();

  bool _isInitialized = false;
  bool _isPlaying = false;
  Song? _currentSong;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 0.7;
  double _speed = 1.0;
  bool _isShuffled = false;
  LoopMode _repeatMode = LoopMode.off;
  List<Song> _currentPlaylist = [];
  int _currentIndex = 0;
  double _bufferedProgress = 0;

  // Listening duration tracker
  final _listenStopwatch = Stopwatch();
  Song? _trackedSong;
  String? _currentUserId;

  // Sleep Timer
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  Timer? _sleepTimerCountdown;
  bool _stopAfterSong = false;

  // Crossfade
  double _crossfadeDuration = 0.0;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  Song? get currentSong => _currentSong;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get volume => _volume;
  double get speed => _speed;
  bool get isShuffled => _isShuffled;
  LoopMode get repeatMode => _repeatMode;
  List<Song> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  double get bufferedProgress => _bufferedProgress;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;
  double get crossfadeDuration => _crossfadeDuration;

  // Progress percentage
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  // Formatted time
  String get currentTime {
    final minutes = _currentPosition.inMinutes;
    final seconds = _currentPosition.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get totalTime {
    final minutes = _totalDuration.inMinutes;
    final seconds = _totalDuration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  PlayerProvider() {
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    await _audioService.initialize();
    _isInitialized = true;

    // Listen to playback info
    _audioService.playbackInfoStream.listen((info) {
      // Detect song change → flush history for previous song
      if (_trackedSong?.id != info.currentSong?.id) {
        _flushListeningHistory();
        _trackedSong = info.currentSong;
        if (info.isPlaying) _listenStopwatch
          ..reset()
          ..start();
      }

      // Manage stopwatch based on play/pause state
      if (info.isPlaying && !_listenStopwatch.isRunning) {
        _listenStopwatch.start();
      } else if (!info.isPlaying && _listenStopwatch.isRunning) {
        _listenStopwatch.stop();
      }

      _currentSong = info.currentSong;
      _currentPosition = info.position;
      _totalDuration = info.duration ?? Duration.zero;
      _isPlaying = info.isPlaying;
      _bufferedProgress = info.progress;
      _currentIndex = info.currentIndex;
      _currentPlaylist = info.playlist;

      notifyListeners();
    });

    // Listen to shuffle mode
    _audioService.shuffleModeStream.listen((shuffled) {
      _isShuffled = shuffled;
      notifyListeners();
    });

    // Listen to repeat mode
    _audioService.repeatModeStream.listen((mode) {
      _repeatMode = mode;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Call this after login/logout to keep history accurate.
  void setUserId(String? uid) {
    _currentUserId = uid;
    _audioService.setUserId(uid);
  }

  void _flushListeningHistory() {
    _listenStopwatch.stop();
    final elapsed = _listenStopwatch.elapsed.inSeconds;
    final song = _trackedSong;
    // Only log if at least 10 s were played to avoid accidental taps
    if (song != null && elapsed >= 10 && _currentUserId != null) {
      FirebaseService()
          .logListeningEvent(
            userId: _currentUserId!,
            songId: song.id,
            duration: elapsed,
          )
          .catchError((e) => AppLogger.error('History flush error: $e'));
    }
    _listenStopwatch.reset();
  }

  // Playback controls
  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    try {
      await _audioService.playSong(song, playlist: playlist);
      _currentSong = song;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error playing song: $e');
      rethrow;
    }
  }

  Future<void> play() async {
    await _audioService.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioService.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    await _audioService.next();
  }

  Future<void> previous() async {
    await _audioService.previous();
  }

  Future<void> seek(double value) async {
    final position = value * _totalDuration.inMilliseconds;
    await _audioService.seek(Duration(milliseconds: position.round()));
  }

  Future<void> seekTo(Duration position) async {
    await _audioService.seek(position);
  }

  // Playlist management
  Future<void> setPlaylist(List<Song> playlist, {int initialIndex = 0}) async {
    await _audioService.setPlaylist(playlist, initialIndex: initialIndex);
    _currentPlaylist = playlist;
    _currentIndex = initialIndex;
    notifyListeners();
  }

  void addToPlaylist(Song song) {
    _currentPlaylist.add(song);
    notifyListeners();
  }

  void removeFromPlaylist(int index) {
    _currentPlaylist.removeAt(index);
    if (_currentIndex >= index && _currentIndex > 0) {
      _currentIndex--;
    }
    notifyListeners();
  }

  void clearPlaylist() {
    _currentPlaylist.clear();
    notifyListeners();
  }

  // Settings
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioService.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _audioService.setSpeed(_speed);
    notifyListeners();
  }

  void toggleShuffle() {
    _audioService.toggleShuffle();
  }

  void toggleRepeat() {
    _audioService.toggleRepeat();
  }

  // Utility methods
  String getRepeatIcon() {
    switch (_repeatMode) {
      case LoopMode.off:
        return 'repeat';
      case LoopMode.all:
        return 'repeat';
      case LoopMode.one:
        return 'repeat_one';
    }
  }

  String getRepeatText() {
    switch (_repeatMode) {
      case LoopMode.off:
        return 'Off';
      case LoopMode.all:
        return 'All';
      case LoopMode.one:
        return 'One';
    }
  }

  // ========== SLEEP TIMER ==========
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepTimerRemaining = duration;
    _stopAfterSong = false;
    notifyListeners();

    _sleepTimerCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sleepTimerRemaining != null && _sleepTimerRemaining!.inSeconds > 0) {
        _sleepTimerRemaining = _sleepTimerRemaining! - const Duration(seconds: 1);
        notifyListeners();
      } else {
        pause();
        cancelSleepTimer();
      }
    });
  }

  void setSleepTimerAfterSong() {
    cancelSleepTimer();
    _stopAfterSong = true;
    _sleepTimerRemaining = null;
    notifyListeners();
    AppLogger.info('Sleep timer: stop after current song');
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerCountdown?.cancel();
    _sleepTimerRemaining = null;
    _stopAfterSong = false;
    notifyListeners();
  }

  // ========== CROSSFADE ==========
  Future<void> setCrossfadeDuration(double seconds) async {
    _crossfadeDuration = seconds.clamp(0.0, 12.0);
    notifyListeners();
    AppLogger.info('Crossfade duration set to ${_crossfadeDuration}s');
  }

  @override
  void dispose() {
    _flushListeningHistory();
    _sleepTimer?.cancel();
    _sleepTimerCountdown?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
