import 'package:harmony_music/core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/song_model.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  User? _user;
  Map<String, dynamic> _profile = {};
  List<Song> _likedSongs = [];
  List<Song> _recentlyPlayed = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  Map<String, dynamic> get profile => _profile;
  List<Song> get likedSongs => _likedSongs;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isPremium => _profile['premium'] ?? false;
  bool get isAdmin => _profile['isAdmin'] ?? false;

  // Constructor
  UserProvider() {
    _authService.user.listen(_onAuthStateChanged);
  }

  // ============= AUTHENTICATION =============

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithEmail(email, password);
      _user = result.user;
      await _loadUserProfile();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: name,
      );
      _user = result.user;
      await _loadUserProfile();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithGoogle();
      _user = result.user;
      await _loadUserProfile();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithApple() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithApple();
      _user = result.user;
      await _loadUserProfile();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAnonymously() async {
    _setLoading(true);
    try {
      final result = await _authService.signInAnonymously();
      _user = result.user;
      await _loadUserProfile();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _profile = {};
      _likedSongs = [];
      _recentlyPlayed = [];
      notifyListeners();
    } catch (e) {
      AppLogger.error('DEBUG AUTH ERROR: $e');
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  // ============= PROFILE MANAGEMENT =============

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      try {
        _profile = await _firebaseService.getUserProfile(_user!.uid);
        await loadLikedSongs();
        await loadRecentlyPlayed();
        notifyListeners();
      } catch (e) {
        AppLogger.error('Error loading user profile: $e');
      }
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      if (_user != null) {
        await _firebaseService.updateUserProfile(_user!.uid, data);
        _profile.addAll(data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDisplayName(String name) async {
    try {
      await _authService.updateDisplayName(name);
      _user = _authService.currentUser;
      await _loadUserProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updatePhotoURL(String url) async {
    try {
      await _authService.updatePhotoURL(url);
      _user = _authService.currentUser;
      await _loadUserProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ============= PASSWORD MANAGEMENT =============

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ============= EMAIL VERIFICATION =============

  Future<bool> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> reloadUser() async {
    try {
      await _authService.reloadUser();
      _user = _authService.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ============= LIKED SONGS =============

  Future<void> loadLikedSongs() async {
    if (_user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('likedSongs')
            .get();

        _likedSongs = [];
        for (final doc in snapshot.docs) {
          final song = await _firebaseService.getSong(doc.id);
          _likedSongs.add(song);
        }
        notifyListeners();
      } catch (e) {
        AppLogger.error('Error loading liked songs: $e');
      }
    }
  }

  Future<bool> likeSong(Song song) async {
    if (_user == null) return false;

    try {
      await _firebaseService.likeSong(song.id, _user!.uid);
      _likedSongs.add(song);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> unlikeSong(String songId) async {
    if (_user == null) return false;

    try {
      await _firebaseService.unlikeSong(songId, _user!.uid);
      _likedSongs.removeWhere((s) => s.id == songId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  bool isSongLiked(String songId) {
    return _likedSongs.any((s) => s.id == songId);
  }

  // ============= RECENTLY PLAYED =============

  Future<void> loadRecentlyPlayed() async {
    if (_user != null) {
      try {
        _recentlyPlayed = await _firebaseService.getRecentlyPlayed(_user!.uid);
        notifyListeners();
      } catch (e) {
        AppLogger.error('Error loading recently played: $e');
      }
    }
  }

  // ============= PREMIUM =============

  Future<bool> upgradeToPremium() async {
    _setLoading(true);
    try {
      // Implement payment integration
      await _firebaseService.updateUserProfile(_user!.uid, {
        'premium': true,
        'premiumSince': DateTime.now().toIso8601String(),
      });
      _profile['premium'] = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelPremium() async {
    _setLoading(true);
    try {
      await _firebaseService.updateUserProfile(_user!.uid, {
        'premium': false,
      });
      _profile['premium'] = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============= ACCOUNT MANAGEMENT =============

  Future<bool> deleteAccount() async {
    _setLoading(true);
    try {
      await _authService.deleteAccount();
      _user = null;
      _profile = {};
      _likedSongs = [];
      _recentlyPlayed = [];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============= LISTENING HISTORY =============

  Future<void> logListeningEvent(Song song, int duration) async {
    if (_user != null) {
      await _firebaseService.logListeningEvent(
        userId: _user!.uid,
        songId: song.id,
        duration: duration,
      );
    }
  }

  // ============= PREFERENCES =============

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (_user != null) {
      try {
        await _firebaseService.updateUserProfile(_user!.uid, {
          'preferences': preferences,
        });
        _profile['preferences'] = preferences;
        notifyListeners();
      } catch (e) {
        _error = e.toString();
      }
    }
  }

  Map<String, dynamic> get preferences {
    return _profile['preferences'] ??
        {
          'theme': 'system',
          'quality': 'high',
          'downloadQuality': 'high',
          'autoPlay': true,
          'explicitContent': true,
        };
  }

  // ============= UTILITIES =============

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _loadUserProfile();
    } else {
      _profile = {};
      _likedSongs = [];
      _recentlyPlayed = [];
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
