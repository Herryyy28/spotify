import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import '../services/audio_service.dart';

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

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
