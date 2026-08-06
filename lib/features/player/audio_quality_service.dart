import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudioQuality { low, normal, high, veryHigh }

class AudioQualityService extends ChangeNotifier {
  AudioQuality _currentQuality = AudioQuality.high;

  AudioQuality get currentQuality => _currentQuality;

  AudioQualityService() {
    _loadQuality();
  }

  Future<void> _loadQuality() async {
    final prefs = await SharedPreferences.getInstance();
    final qualityIndex = prefs.getInt('audio_quality') ?? AudioQuality.high.index;
    _currentQuality = AudioQuality.values[qualityIndex];
    notifyListeners();
  }

  Future<void> setQuality(AudioQuality quality) async {
    _currentQuality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('audio_quality', quality.index);
    notifyListeners();
    
    // In a real implementation, this would inform the AudioService
    // to switch streaming URLs (e.g. 96kbps vs 320kbps) for the next track.
  }
}
