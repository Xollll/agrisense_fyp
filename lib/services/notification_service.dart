// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:agrisense/utils/app_log.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize notifications
  Future<void> initialize() async {
    try {
      // Android initialization
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      // Combined initialization
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          appLog('Notification tapped: ${response.payload}');
        },
      );

      // Request permissions for iOS
      await _requestIOSPermissions();

      appLog('Notification service initialized');
    } catch (e) {
      appLog('Error initializing notifications: $e');
    }
  }

  /// Request iOS notification permissions
  Future<void> _requestIOSPermissions() async {
    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      appLog('iOS notification permissions requested');
    } catch (e) {
      appLog('Error requesting iOS permissions: $e');
    }
  }

  /// Show disease detection notification
  Future<void> showDiseaseDetectionNotification({
    required String diseaseName,
    required double confidence,
    required String? solution,
  }) async {
    try {
      final String title = '🚨 Disease Detected';
      final String body = '$diseaseName (${(confidence * 100).toStringAsFixed(1)}% confidence)';
      final String payload = '$diseaseName|$confidence';

      // Android notification details
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'disease_detection_channel',
        'Disease Detections',
        channelDescription: 'Notifications for detected plant diseases',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        ticker: 'Disease Detected',
        styleInformation: BigTextStyleInformation(''),
      );

      // iOS notification details
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentSound: true,
        presentBadge: true,
        presentAlert: true,
        badgeNumber: 1,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      appLog('Disease notification sent: $diseaseName');
    } catch (e) {
      appLog('Error showing notification: $e');
    }
  }

  /// Show AI recommendation notification
  Future<void> showRecommendationNotification({
    required String diseaseName,
    required String? recommendation,
  }) async {
    try {
      final String title = '💡 AI Recommendation';
      final String body = recommendation ?? 'Check the app for recommendations';

      // Android notification details
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'recommendation_channel',
        'AI Recommendations',
        channelDescription: 'AI-generated recommendations for detected diseases',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        ticker: 'New Recommendation',
      );

      // iOS notification details
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentSound: true,
        presentBadge: false,
        presentAlert: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: diseaseName,
      );

      appLog('Recommendation notification sent');
    } catch (e) {
      appLog('Error showing recommendation notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      appLog('All notifications cancelled');
    } catch (e) {
      appLog('Error cancelling notifications: $e');
    }
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      appLog('Notification $id cancelled');
    } catch (e) {
      appLog('Error cancelling notification: $e');
    }
  }
}
