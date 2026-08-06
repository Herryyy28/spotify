import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../providers/player_provider.dart';

class SleepTimerService extends ChangeNotifier {
  final PlayerProvider playerProvider;
  Timer? _timer;
  Duration? _timeRemaining;
  bool _stopAfterCurrentSong = false;

  SleepTimerService(this.playerProvider);

  Duration? get timeRemaining => _timeRemaining;
  bool get stopAfterCurrentSong => _stopAfterCurrentSong;
  bool get isActive => _timer != null || _stopAfterCurrentSong;

  void startTimer(Duration duration) {
    cancelTimer();
    _timeRemaining = duration;
    _stopAfterCurrentSong = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining != null && _timeRemaining!.inSeconds > 0) {
        _timeRemaining = _timeRemaining! - const Duration(seconds: 1);
        notifyListeners();
      } else {
        _executeSleep();
      }
    });
    notifyListeners();
  }

  void startStopAfterCurrentSong() {
    cancelTimer();
    _stopAfterCurrentSong = true;
    notifyListeners();
    // In a real implementation, we would listen to PlayerProvider's state stream
    // to detect when the song finishes and then call _executeSleep().
  }

  void _executeSleep() {
    cancelTimer();
    playerProvider.pause();
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _timeRemaining = null;
    _stopAfterCurrentSong = false;
    notifyListeners();
  }
}
