import 'dart:async';
import 'package:flutter/material.dart';
import 'package:harmony_music/core/utils/logger.dart';
import '../models/listening_room_model.dart';
import '../models/song_model.dart';
import '../services/listening_room_service.dart';
import '../providers/player_provider.dart';

class ListeningRoomProvider extends ChangeNotifier {
  final ListeningRoomService _service = ListeningRoomService();

  ListeningRoom? _activeRoom;
  List<RoomMessage> _messages = [];
  StreamSubscription<ListeningRoom?>? _roomSubscription;
  StreamSubscription<List<RoomMessage>>? _messagesSubscription;

  bool _isHost = false;
  bool _isLoading = false;
  String? _error;

  ListeningRoom? get activeRoom => _activeRoom;
  List<RoomMessage> get messages => _messages;
  bool get isInRoom => _activeRoom != null;
  bool get isHost => _isHost;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Creates a new room with current playing song or default demo song.
  Future<ListeningRoom?> createRoom(Song initialSong, String hostName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final room = await _service.createRoom(
        song: initialSong,
        hostName: hostName,
      );
      _activeRoom = room;
      _isHost = true;
      _listenToRoomStream(room.id);
      return room;
    } catch (e) {
      _error = 'Failed to create room: $e';
      AppLogger.error(_error!);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Joins an existing room by Room Code (e.g. ROOM-4829).
  Future<bool> joinRoom(String roomId, PlayerProvider playerProvider) async {
    final formattedId = roomId.trim().toUpperCase();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _listenToRoomStream(formattedId, playerProvider: playerProvider);
      _isHost = false;
      return true;
    } catch (e) {
      _error = 'Could not find room: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Broadcasts host's local playback changes to all listeners in room.
  void broadcastPlaybackChange({
    required Song song,
    required double positionInSeconds,
    required bool isPlaying,
  }) {
    if (!_isHost || _activeRoom == null) return;
    _service.updateRoomPlayback(
      roomId: _activeRoom!.id,
      song: song,
      positionInSeconds: positionInSeconds,
      isPlaying: isPlaying,
    );
  }

  /// Sends a live message or reaction emoji.
  Future<void> sendReaction(String message, {bool isEmojiOnly = false}) async {
    if (_activeRoom == null) return;
    await _service.sendRoomMessage(
      roomId: _activeRoom!.id,
      message: message,
      isEmojiOnly: isEmojiOnly,
    );
  }

  /// Subscribes to real-time room updates & synchronizes non-host player.
  void _listenToRoomStream(String roomId, {PlayerProvider? playerProvider}) {
    _roomSubscription?.cancel();
    _messagesSubscription?.cancel();

    _roomSubscription = _service.streamRoom(roomId).listen((room) {
      if (room == null) {
        // Room was closed or deleted
        leaveRoom();
        return;
      }
      _activeRoom = room;

      // Auto-sync listener player state if not host
      if (!_isHost && playerProvider != null) {
        if (playerProvider.currentSong?.id != room.currentSong.id) {
          playerProvider.playSong(room.currentSong);
        }
        if (room.isPlaying && !playerProvider.isPlaying) {
          playerProvider.play();
        } else if (!room.isPlaying && playerProvider.isPlaying) {
          playerProvider.pause();
        }
      }

      notifyListeners();
    });

    _messagesSubscription = _service.streamRoomMessages(roomId).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    });
  }

  /// Leaves the current active room.
  Future<void> leaveRoom() async {
    if (_activeRoom != null) {
      await _service.leaveRoom(_activeRoom!.id, _isHost);
    }
    _roomSubscription?.cancel();
    _messagesSubscription?.cancel();
    _activeRoom = null;
    _isHost = false;
    _messages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
