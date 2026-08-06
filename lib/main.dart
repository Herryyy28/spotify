import 'package:harmony_music/core/utils/logger.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'app/app.dart';

bool _firebaseInitialized = false;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.info('Starting app initialization...');

    // Initialize Hive
    try {
      await Hive.initFlutter();
      await Hive.openBox('downloads');
      await Hive.openBox('user_cache');
      AppLogger.info('Hive initialized');
    } catch (e) {
      AppLogger.error('Error initializing Hive: $e');
    }

    // Initialize audio background service
    if (!kIsWeb) {
      try {
        await JustAudioBackground.init(
          androidNotificationChannelId: 'com.example.music.channel.audio',
          androidNotificationChannelName: 'Music Playback',
          androidNotificationOngoing: true,
        );
        AppLogger.info('Audio service initialized');
      } catch (e) {
        AppLogger.error('Error initializing audio service: $e');
      }
    } else {
      AppLogger.info('Running on Web: skipped background audio service initialization');
    }

    // Initialize Firebase
    try {
      if (DefaultFirebaseOptions.android.apiKey == 'YOUR_ANDROID_API_KEY' &&
          defaultTargetPlatform == TargetPlatform.android) {
        // Fallback to default initialization for Android if placeholders are still present
        await Firebase.initializeApp();
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseInitialized = true;
      AppLogger.info('Firebase initialized successfully');
    } catch (e) {
      _firebaseInitialized = false;
      AppLogger.error('Error initializing Firebase: $e');
      AppLogger.info(
        'Note: Firebase requires google-services.json on Android or GoogleService-Info.plist on iOS.',
      );
      AppLogger.info(
        'Run "flutterfire configure" to generate Firebase configuration files.',
      );
    }

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (e) {
    AppLogger.error('Critical error during initialization: $e');
  }

  runApp(HarmonyApp(
    firebaseInitialized: _firebaseInitialized,
    onboardingComplete: (await SharedPreferences.getInstance())
            .getBool('onboarding_complete') ??
        false,
  ));
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
