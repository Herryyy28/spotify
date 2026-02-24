import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/song_model.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final _playlist = BehaviorSubject<List<Song>>.seeded([]);
  final _currentIndex = BehaviorSubject<int>.seeded(0);
  final _repeatMode = BehaviorSubject<LoopMode>.seeded(LoopMode.off);
  final _shuffleMode = BehaviorSubject<bool>.seeded(false);
  final _shuffledIndices = BehaviorSubject<List<int>>.seeded([]);

  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _bufferedPositionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _currentIndexSubscription;

  // Cache manager for audio files
  final CacheManager _cacheManager = CacheManager(
    Config(
      'audio_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 50,
    ),
  );

  // Public streams
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<List<Song>> get playlistStream => _playlist.stream;
  Stream<int> get currentIndexStream => _currentIndex.stream;
  Stream<LoopMode> get repeatModeStream => _repeatMode.stream;
  Stream<bool> get shuffleModeStream => _shuffleMode.stream;

  // Combined stream for UI
  Stream<PlaybackInfo> get playbackInfoStream => Rx.combineLatest6(
        positionStream,
        bufferedPositionStream,
        durationStream,
        playerStateStream,
        currentIndexStream,
        playlistStream,
        (position, buffered, duration, state, index, playlist) => PlaybackInfo(
          position: position,
          bufferedPosition: buffered,
          duration: duration,
          playerState: state,
          currentIndex: index,
          currentSong: playlist.isNotEmpty ? playlist[index] : null,
          playlist: playlist,
        ),
      );

  Future<void> initialize() async {
    // Setup audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to audio interruptions
    _audioPlayer.playbackEventStream.listen((event) {
      // Handle playback events
    }, onError: (Object e, StackTrace stackTrace) {
      print('Audio error: $e');
    });

    // Set up audio loading interceptor
    _audioPlayer.setAudioSource(_createPlaylistSource());

    // Initialize shuffle indices
    _updateShuffledIndices();
  }

  ConcatenatingAudioSource _createPlaylistSource() {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: _playlist.value.map((song) {
        return AudioSource.uri(
          Uri.parse(song.audioUrl),
          tag: song,
        );
      }).toList(),
    );
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    try {
      if (playlist != null) {
        await setPlaylist(playlist, initialIndex: playlist.indexOf(song));
      }

      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(song.audioUrl)),
      );
      await _audioPlayer.play();

      // Update last played
      _updateLastPlayed(song);
    } catch (e) {
      print('Error playing song: $e');
      rethrow;
    }
  }

  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();
  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  Future<void> next() async {
    if (_playlist.value.isEmpty) return;

    int nextIndex = _getNextIndex();
    if (nextIndex < _playlist.value.length) {
      await _audioPlayer.seek(Duration.zero);
      await playSong(_playlist.value[nextIndex]);
      _currentIndex.add(nextIndex);
    }
  }

  Future<void> previous() async {
    if (_playlist.value.isEmpty) return;

    final currentPosition = _audioPlayer.position;
    if (currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
    } else {
      int prevIndex = _getPreviousIndex();
      if (prevIndex >= 0) {
        await playSong(_playlist.value[prevIndex]);
        _currentIndex.add(prevIndex);
      }
    }
  }

  int _getNextIndex() {
    if (_shuffleMode.value) {
      final current = _shuffledIndices.value.indexOf(_currentIndex.value);
      return _shuffledIndices
          .value[(current + 1) % _shuffledIndices.value.length];
    }

    switch (_repeatMode.value) {
      case LoopMode.off:
        return _currentIndex.value + 1;
      case LoopMode.one:
        return _currentIndex.value;
      case LoopMode.all:
        return (_currentIndex.value + 1) % _playlist.value.length;
    }
  }

  int _getPreviousIndex() {
    if (_shuffleMode.value) {
      final current = _shuffledIndices.value.indexOf(_currentIndex.value);
      return _shuffledIndices
          .value[(current - 1).clamp(0, _shuffledIndices.value.length - 1)];
    }

    switch (_repeatMode.value) {
      case LoopMode.off:
        return _currentIndex.value - 1;
      case LoopMode.one:
        return _currentIndex.value;
      case LoopMode.all:
        return (_currentIndex.value - 1 + _playlist.value.length) %
            _playlist.value.length;
    }
  }

  Future<void> setPlaylist(List<Song> playlist, {int initialIndex = 0}) async {
    _playlist.add(playlist);
    _currentIndex.add(initialIndex);
    _updateShuffledIndices();

    await _audioPlayer.setAudioSource(
      ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: playlist.map((song) {
          return AudioSource.uri(
            Uri.parse(song.audioUrl),
            tag: song,
          );
        }).toList(),
      ),
      initialIndex: initialIndex,
    );
  }

  void toggleShuffle() {
    _shuffleMode.add(!_shuffleMode.value);
    _updateShuffledIndices();
  }

  void toggleRepeat() {
    switch (_repeatMode.value) {
      case LoopMode.off:
        _repeatMode.add(LoopMode.all);
        break;
      case LoopMode.all:
        _repeatMode.add(LoopMode.one);
        break;
      case LoopMode.one:
        _repeatMode.add(LoopMode.off);
        break;
    }
    _audioPlayer.setLoopMode(_repeatMode.value);
  }

  void _updateShuffledIndices() {
    if (_shuffleMode.value) {
      final indices = List.generate(_playlist.value.length, (i) => i);
      indices.shuffle();
      _shuffledIndices.add(indices);
    }
  }

  Future<String?> getCachedAudio(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        return fileInfo.file.path;
      }

      final file = await _cacheManager.getSingleFile(url);
      return file.path;
    } catch (e) {
      print('Error caching audio: $e');
      return null;
    }
  }

  void _updateLastPlayed(Song song) {
    // Update last played in database
    // Increment play count
  }

  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _bufferedPositionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _currentIndexSubscription?.cancel();
    await _audioPlayer.dispose();
    await _playlist.close();
    await _currentIndex.close();
    await _repeatMode.close();
    await _shuffleMode.close();
    await _shuffledIndices.close();
  }

  // Volume control
  Future<void> setVolume(double volume) =>
      _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  double get volume => _audioPlayer.volume;

  // Speed control
  Future<void> setSpeed(double speed) =>
      _audioPlayer.setSpeed(speed.clamp(0.5, 2.0));
  double get speed => _audioPlayer.speed;

  // Equalizer
  // Add equalizer implementation here

  // Crossfade
  Future<void> setCrossfade(Duration duration) {
    // Implement crossfade
    return Future.value();
  }
}

class PlaybackInfo {
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;
  final PlayerState playerState;
  final int currentIndex;
  final Song? currentSong;
  final List<Song> playlist;

  PlaybackInfo({
    required this.position,
    required this.bufferedPosition,
    this.duration,
    required this.playerState,
    required this.currentIndex,
    this.currentSong,
    required this.playlist,
  });

  bool get isPlaying => playerState.playing;
  bool get isBuffering =>
      playerState.processingState == ProcessingState.buffering;
  bool get isReady => playerState.processingState == ProcessingState.ready;
  bool get isCompleted =>
      playerState.processingState == ProcessingState.completed;

  double get progress {
    if (duration == null || duration!.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration!.inMilliseconds;
  }

  String get currentTime => _formatDuration(position);
  String get totalTime => _formatDuration(duration ?? Duration.zero);

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
