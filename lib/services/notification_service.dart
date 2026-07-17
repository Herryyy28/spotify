import 'package:harmony_music/core/utils/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize local notifications
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Request FCM permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('Push notification permission granted');

        // Get FCM token
        final token = await messaging.getToken();
        AppLogger.info('FCM Token: $token');

        // Subscribe to default topics
        await _subscribeToDefaultTopics();

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);

        // Handle background message taps
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
      } else {
        AppLogger.info('Push notification permission: ${settings.authorizationStatus}');
      }

      _initialized = true;
    } catch (e) {
      AppLogger.error('Error initializing notifications: $e');
    }
  }

  Future<void> _subscribeToDefaultTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final messaging = FirebaseMessaging.instance;

    if (prefs.getBool('notif_new_releases') ?? true) {
      await messaging.subscribeToTopic('new_releases');
    }
    if (prefs.getBool('notif_weekly_digest') ?? true) {
      await messaging.subscribeToTopic('weekly_digest');
    }
    if (prefs.getBool('notif_playlist_updates') ?? true) {
      await messaging.subscribeToTopic('playlist_updates');
    }
  }

  Future<void> updateTopicSubscription(String topic, bool subscribe) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final prefs = await SharedPreferences.getInstance();

      if (subscribe) {
        await messaging.subscribeToTopic(topic);
        AppLogger.info('Subscribed to topic: $topic');
      } else {
        await messaging.unsubscribeFromTopic(topic);
        AppLogger.info('Unsubscribed from topic: $topic');
      }

      await prefs.setBool('notif_$topic', subscribe);
    } catch (e) {
      AppLogger.error('Error updating topic subscription: $e');
    }
  }

  Future<bool> isSubscribed(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notif_$topic') ?? true;
  }

  void _onForegroundMessage(RemoteMessage message) {
    AppLogger.info('Foreground message: ${message.notification?.title}');
    _showLocalNotification(
      title: message.notification?.title ?? 'Harmony Music',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('Notification tapped: ${message.data}');
    // Handle navigation based on message data
  }

  void _onNotificationTap(NotificationResponse response) {
    AppLogger.info('Local notification tapped: ${response.payload}');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'harmony_music_channel',
      'Harmony Music',
      channelDescription: 'Harmony Music notifications',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showNowPlayingNotification(String title, String artist) async {
    await _showLocalNotification(
      title: '🎵 Now Playing',
      body: '$title · $artist',
    );
  }
}
