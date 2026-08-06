import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart' hide AppTheme;
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/user_provider.dart';
import '../providers/music_provider.dart';
import '../providers/search_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/analytics_provider.dart';
import '../providers/social_provider.dart';
import '../providers/podcast_provider.dart';
import '../providers/listening_room_provider.dart';
import '../providers/song_upload_provider.dart';
import 'theme/app_theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/upload_song_screen.dart';
import '../screens/social/listen_room_screen.dart';

class HarmonyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final bool onboardingComplete;

  const HarmonyApp({
    super.key,
    required this.firebaseInitialized,
    this.onboardingComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => PodcastProvider()),
        ChangeNotifierProvider(create: (_) => ListeningRoomProvider()),
        ChangeNotifierProvider(create: (_) => SongUploadProvider()),
        if (firebaseInitialized) ...[
          // Wire UserProvider after PlayerProvider so auth state forwards userId
          ChangeNotifierProxyProvider<PlayerProvider, UserProvider>(
            create: (_) => UserProvider(),
            update: (_, player, user) {
              user!.attachPlayerProvider(player);
              return user;
            },
          ),
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => RecommendationProvider()),
          ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
          ChangeNotifierProvider(create: (_) => SocialProvider()),
        ],
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Harmony Music',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeModeValue,
            initialRoute: onboardingComplete ? '/' : '/onboarding',
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/': (context) => Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      if (!firebaseInitialized) {
                        return const Scaffold(
                          body: Center(
                            child: Text(
                              'Firebase Initialization Failed.\nCheck configuration.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      if (userProvider.isLoading) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return userProvider.isAuthenticated
                          ? const MainScreen()
                          : const LoginScreen();
                    },
                  ),
              '/admin': (context) => const AdminDashboardScreen(),
              '/admin/upload': (context) => const UploadSongScreen(),
              '/social/room': (context) => const ListenRoomScreen(),
            },
          );
        },
      ),
    );
  }
}
