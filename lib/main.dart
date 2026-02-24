import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

import 'providers/theme_provider.dart' hide AppTheme;
import 'providers/player_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/user_provider.dart';
import 'providers/music_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/analytics_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

bool _firebaseInitialized = false;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Starting app initialization...');

    // Initialize Hive
    try {
      await Hive.initFlutter();
      await Hive.openBox('downloads');
      print('Hive initialized');
    } catch (e) {
      print('Error initializing Hive: $e');
    }

    // Initialize audio background service
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.example.music.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      );
      print('Audio service initialized');
    } catch (e) {
      print('Error initializing audio service: $e');
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
      print('Firebase initialized successfully');
    } catch (e) {
      _firebaseInitialized = false;
      print('Error initializing Firebase: $e');
      print(
        'Note: Firebase requires google-services.json on Android or GoogleService-Info.plist on iOS.',
      );
      print(
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
    print('Critical error during initialization: $e');
  }

  runApp(MyApp(firebaseInitialized: _firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;

  const MyApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        if (firebaseInitialized) ...[
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => MusicProvider()),
          ChangeNotifierProvider(create: (_) => RecommendationProvider()),
          ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
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
                      return userProvider.isAuthenticated
                          ? const MainScreen()
                          : const LoginScreen();
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
