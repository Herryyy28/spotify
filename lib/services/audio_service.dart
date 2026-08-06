import 'package:harmony_music/core/utils/logger.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/song_model.dart';
import '../data/repositories/firestore_song_repository.dart';
import '../data/repositories/firestore_user_repository.dart';

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

  // User ID for history logging (set after login)
  String? _currentUserId;
  void setUserId(String? uid) => _currentUserId = uid;

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

  late ConcatenatingAudioSource _playlistSource;

  Future<void> initialize() async {
    // Setup audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to audio interruptions (phone calls, notifications, etc.)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _audioPlayer.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _audioPlayer.pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _audioPlayer.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            _audioPlayer.play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    // Pause when headphones are unplugged (noisy event)
    session.becomingNoisyEventStream.listen((_) {
      _audioPlayer.pause();
    });

    // Listen to audio playback events
    _audioPlayer.playbackEventStream.listen((event) {
      // Handle playback events
    }, onError: (Object e, StackTrace stackTrace) {
      AppLogger.error('Audio error: $e');
    });

    _playlistSource = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: [],
    );
    await _audioPlayer.setAudioSource(_playlistSource);

    // Track sequence state to update our BehaviorSubject
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      final sequence = sequenceState.sequence;
      
      final currentSongs = sequence.map((indexedAudioSource) {
        final tag = indexedAudioSource.tag;
        if (tag is MediaItem && tag.extras != null && tag.extras!['song'] != null) {
          return Song.fromJson(tag.extras!['song'] as Map<String, dynamic>);
        } else if (tag is MediaItem) {
           return Song(
            id: tag.id,
            title: tag.title,
            artist: tag.artist ?? 'Unknown Artist',
            album: tag.album ?? 'Unknown Album',
            coverUrl: tag.artUri?.toString() ?? '',
            audioUrl: '', // URL is not strictly needed back here
            duration: '',
            durationInSeconds: 0,
            releaseDate: DateTime.now(),
          );
        }
        return null;
      }).whereType<Song>().toList();
      
      _playlist.add(currentSongs);
      _currentIndex.add(sequenceState.currentIndex);
      _updateShuffledIndices();
    });
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    try {
      if (playlist != null) {
        await setPlaylist(playlist, initialIndex: playlist.indexOf(song));
      }

      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.audioUrl),
          tag: kIsWeb
              ? null
              : MediaItem(
                  id: song.id,
                  album: song.artist,
                  title: song.title,
                  artUri: Uri.parse(song.coverUrl),
                ),
        ),
      );
      await _audioPlayer.play();

      // Update last played
      _updateLastPlayed(song);
    } catch (e) {
      AppLogger.error('Error playing song: $e');
      rethrow;
    }
  }

  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();
  Future<void> seek(Duration position) => _audioPlayer.seek(position);
  
  Future<void> seekToIndex(int index) async {
    if (index >= 0 && index < _playlistSource.length) {
      await _audioPlayer.seek(Duration.zero, index: index);
    }
  }

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
    final audioSources = playlist.map((song) => AudioSource.uri(
      Uri.parse(song.audioUrl),
      tag: kIsWeb ? null : MediaItem(
        id: song.id,
        album: song.artist,
        title: song.title,
        artUri: Uri.parse(song.coverUrl),
        extras: {'song': song.toJson()},
      ),
    )).toList();

    await _playlistSource.clear();
    await _playlistSource.addAll(audioSources);
    
    if (playlist.isNotEmpty) {
      await _audioPlayer.seek(Duration.zero, index: initialIndex);
    }
  }

  Future<void> addNext(Song song) async {
    final index = (_audioPlayer.currentIndex ?? -1) + 1;
    await _playlistSource.insert(index, AudioSource.uri(
      Uri.parse(song.audioUrl),
      tag: kIsWeb ? null : MediaItem(
        id: song.id,
        album: song.artist,
        title: song.title,
        artUri: Uri.parse(song.coverUrl),
        extras: {'song': song.toJson()},
      ),
    ));
  }

  Future<void> addToQueue(Song song) async {
    await _playlistSource.add(AudioSource.uri(
      Uri.parse(song.audioUrl),
      tag: kIsWeb ? null : MediaItem(
        id: song.id,
        album: song.artist,
        title: song.title,
        artUri: Uri.parse(song.coverUrl),
        extras: {'song': song.toJson()},
      ),
    ));
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1; // Adjust for the item being removed before insertion
    }
    await _playlistSource.move(oldIndex, newIndex);
  }

  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _playlistSource.length) {
      await _playlistSource.removeAt(index);
    }
  }

  Future<void> clearQueue() async {
    await _playlistSource.clear();
  }

  void toggleShuffle() {
    _shuffleMode.add(!_shuffleMode.value);
    _audioPlayer.setShuffleModeEnabled(_shuffleMode.value);
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
      AppLogger.error('Error caching audio: $e');
      return null;
    }
  }

  void _updateLastPlayed(Song song) {
    // Increment play count in Firestore (fire-and-forget)
    FirestoreSongRepository().incrementPlayCount(song.id);

    // Log to user's listening history if signed in
    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      FirestoreUserRepository().logListeningEvent(
        uid,
        song.id,
        10, // Assuming a baseline tracking.
      ).catchError((e) => AppLogger.error('History log error: $e'));
    }
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
