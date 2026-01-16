import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM: User granted permission');

        _fcmToken = await _messaging.getToken();
        debugPrint('✅ FCM Token: $_fcmToken');

        if (_fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', _fcmToken!);
        }

        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }

        _messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token refreshed: $newToken');
          _fcmToken = newToken;
          _saveTokenToServer(newToken);
        });

        debugPrint('✅ FCM Service initialized successfully');
      } else {
        debugPrint('❌ FCM: User declined or has not granted permission');
      }
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message received:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Notification tapped:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Data: ${message.data}');

    String? type = message.data['type'];
    switch (type) {
      case 'attendance':
        debugPrint('   → Navigate to Attendance screen');

        break;
      case 'quiz':
        debugPrint('   → Navigate to Quiz screen');

        break;
      case 'homework':
        debugPrint('   → Navigate to Homework screen');

        break;
      default:
        debugPrint('   → Navigate to Home screen');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    try {

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      debugPrint('✅ FCM token saved: $token');
    } catch (e) {
      debugPrint('❌ Failed to save token to server: $e');
    }
  }

  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('❌ Failed to get saved token: $e');
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      _fcmToken = null;
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete token: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      NotificationSettings settings =
          await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('❌ Failed to check notification settings: $e');
      return false;
    }
  }
}
