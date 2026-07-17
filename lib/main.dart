import 'package:harmony_music/core/utils/logger.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'providers/theme_provider.dart' hide AppTheme;
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/user_provider.dart';
import 'providers/music_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/social_provider.dart';
import 'providers/podcast_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/notification_service.dart';

bool _firebaseInitialized = false;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.info('Starting app initialization...');

    // Initialize Hive
    try {
      await Hive.initFlutter();
      await Hive.openBox('downloads');
      AppLogger.info('Hive initialized');
    } catch (e) {
      AppLogger.error('Error initializing Hive: $e');
    }

    // Initialize audio background service
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

  runApp(MyApp(
    firebaseInitialized: _firebaseInitialized,
    onboardingComplete: (await SharedPreferences.getInstance()).getBool('onboarding_complete') ?? false,
  ));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final bool onboardingComplete;

  const MyApp({super.key, required this.firebaseInitialized, this.onboardingComplete = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => PodcastProvider()),
        if (firebaseInitialized) ...[
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => MusicProvider()),
          ChangeNotifierProvider(create: (_) => RecommendationProvider()),
          ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
          ChangeNotifierProvider(create: (_) => SocialProvider()),
        ],
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Spotify',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeModeValue,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('es', ''),
              Locale('fr', ''),
            ],
            home: firebaseInitialized
                ? Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      if (!userProvider.isAuthenticated) return const LoginScreen();
                      if (!onboardingComplete) return const OnboardingScreen();
                      return const MainScreen();
                    },
                  )
                : const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Firebase Not Initialized',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Please ensure google-services.json is placed in android/app/ directory.\n\nRun "flutterfire configure" to generate Firebase configuration.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: MyCustomScrollBehavior(),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
