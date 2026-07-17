import 'package:harmony_music/core/utils/logger.dart';
import 'package:flutter/material.dart';
import '../models/social_model.dart';
import '../models/song_model.dart';
import '../services/social_service.dart';

class SocialProvider extends ChangeNotifier {
  final SocialService _service = SocialService();

  List<FriendProfile> _following = [];
  List<FriendProfile> _followers = [];
  List<UserActivity> _friendsActivity = [];
  bool _isLoading = false;
  String? _error;

  List<FriendProfile> get following => _following;
  List<FriendProfile> get followers => _followers;
  List<UserActivity> get friendsActivity => _friendsActivity;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SocialProvider() {
    loadSocialData();
  }

  Future<void> loadSocialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getFollowing(),
        _service.getFollowers(),
        _service.getFriendsActivity(),
      ]);
      _following = results[0] as List<FriendProfile>;
      _followers = results[1] as List<FriendProfile>;
      _friendsActivity = results[2] as List<UserActivity>;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error loading social data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> followUser(String userId) async {
    await _service.followUser(userId);
    // Update the isFollowing state optimistically
    _following = _following.map((f) {
      if (f.id == userId) return f.copyWith(isFollowing: true);
      return f;
    }).toList();
    notifyListeners();
    await loadSocialData();
  }

  Future<void> unfollowUser(String userId) async {
    await _service.unfollowUser(userId);
    _following = _following.where((f) => f.id != userId).toList();
    notifyListeners();
  }

  Future<bool> isFollowing(String userId) => _service.isFollowing(userId);

  Future<void> postActivity(Song song, ActivityType type) async {
    await _service.postActivity(song, type);
  }

  Future<void> refreshActivity() async {
    final activity = await _service.getFriendsActivity();
    _friendsActivity = activity;
    notifyListeners();
  }
}
